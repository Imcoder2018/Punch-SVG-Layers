// scene3d.ts
//
// This module is the ONE place that knows how to build the papercut-mockup
// 3D scene (frame + layered artwork + lighting/shadows). Both the live
// preview and the "Export Mockup" / "Screenshot" buttons call the exact
// same `buildPaperCutScene()` function and render it with the exact same
// `renderSceneToCanvas()` function — just at different canvas sizes.
//
// This is what replaces the old pair of independent renderers
// (CSS 3D transforms for preview vs. a hand-derived 2D canvas projection
// for export) that could — and did — drift apart.

import * as THREE from 'three';

export interface SvgData {
  viewBox: string;
  defs: string;
  style: string;
}

export interface LayerLike {
  id: string;
  content: string;
  visible: boolean;
  color?: string;
}

export interface SceneParams {
  artScale: number;
  artPosX: number; // 0-100 (%)
  artPosY: number; // 0-100 (%)
  artRotX: number; // deg
  artRotY: number; // deg
  artRotZ: number; // deg

  frameType: 'flat' | '3d';
  frameColor: string;
  frameWidth: number; // px
  layerDistance: number; // px

  // These used to drive a hand-baked CSS/canvas drop-shadow.
  // Here they drive a *real* shadow-casting light instead, so the
  // "gap between layers" is an actual cast shadow, not a faked one.
  shadowX: number;
  shadowY: number;
  shadowBlur: number;
  shadowOpacity: number; // 0-100
}

// World-unit constants — kept identical to the old CSS stage (800px
// viewport, 500px frame box) so existing slider ranges still feel right.
export const STAGE = 800;
export const BOX = 500;
export const PERSPECTIVE = 1200; // matches the old CSS `perspective: 1200px`

export interface BuiltScene {
  scene: THREE.Scene;
  camera: THREE.PerspectiveCamera;
  artGroup: THREE.Group;
  dispose: () => void;
}

/** Rasterize one SVG layer (with its color override applied) to a canvas texture source. */
export async function rasterizeLayer(
  svgData: SvgData,
  layer: LayerLike,
  size = 1024
): Promise<HTMLCanvasElement | null> {
  const svgStr = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${svgData.viewBox}" width="${size}" height="${size}" preserveAspectRatio="xMidYMid meet">
    <defs>${svgData.defs}</defs>
    <style>${svgData.style}${layer.color ? `* { fill: ${layer.color} !important; stroke: ${layer.color} !important; }` : ''}</style>
    <g>${layer.content}</g>
  </svg>`;
  const blob = new Blob([svgStr], { type: 'image/svg+xml;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const img = await new Promise<HTMLImageElement | null>((res) => {
    const i = new Image();
    i.onload = () => { URL.revokeObjectURL(url); res(i); };
    i.onerror = () => { URL.revokeObjectURL(url); res(null); };
    i.src = url;
  });
  if (!img) return null;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');
  if (!ctx) return null;
  ctx.drawImage(img, 0, 0, size, size);
  return canvas;
}

/**
 * Build the full 3D scene: frame (extruded ring mesh — front/back caps and
 * inner/outer walls all come from ONE geometry, so they can never disagree
 * with each other the way the old hand-drawn quads could) + one plane per
 * visible layer, each at its own real Z depth + a shadow-casting light.
 */
export function buildPaperCutScene(
  params: SceneParams,
  layers: { layer: LayerLike; texture: HTMLCanvasElement | null }[]
): BuiltScene {
  const scene = new THREE.Scene();

  const vFov = 2 * Math.atan((STAGE / 2) / PERSPECTIVE) * (180 / Math.PI);
  const camera = new THREE.PerspectiveCamera(vFov, 1, 1, 5000);
  camera.position.set(0, 0, PERSPECTIVE);
  camera.lookAt(0, 0, 0);

  const {
    artScale, artPosX, artPosY, artRotX, artRotY, artRotZ,
    frameType, frameColor, frameWidth, layerDistance,
    shadowX, shadowY, shadowBlur, shadowOpacity,
  } = params;

  const artGroup = new THREE.Group();

  // Mirrors the old CSS: translate(-50%,-50%) scale(s) rotateX(x) rotateY(y) rotateZ(z)
  const offsetX = (artPosX / 100) * STAGE - STAGE / 2;
  const offsetY = -((artPosY / 100) * STAGE - STAGE / 2); // screen-down -> world-up
  artGroup.position.set(offsetX, offsetY, 0);
  artGroup.scale.set(artScale, artScale, artScale);

  // Rotation order matched to the CSS composition order (Rz applied to the
  // point first, then Ry, then Rx => object matrix = Rx * Ry * Rz).
  // NOTE: if a rotation direction ever looks mirrored vs. the old UI,
  // flip the sign on that one axis below — it's a one-line tweak, and
  // because preview + export share this function, fixing it here fixes
  // both at once instead of needing to be fixed twice.
  const qx = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1, 0, 0), -THREE.MathUtils.degToRad(artRotX));
  const qy = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0, 1, 0), THREE.MathUtils.degToRad(artRotY));
  const qz = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0, 0, 1), -THREE.MathUtils.degToRad(artRotZ));
  artGroup.quaternion.copy(qx.clone().multiply(qy).multiply(qz));

  scene.add(artGroup);

  const visibleLayers = layers.filter(l => l.layer.visible);
  const frameDepth = Math.max(40, visibleLayers.length * layerDistance + 20);
  const half = BOX / 2;
  const halfInner = half - frameWidth;
  const innerSize = halfInner * 2;

  const disposables: { dispose: () => void }[] = [];

  if (frameType === '3d') {
    const outer = new THREE.Shape();
    outer.moveTo(-half, -half);
    outer.lineTo(half, -half);
    outer.lineTo(half, half);
    outer.lineTo(-half, half);
    outer.closePath();

    const hole = new THREE.Path();
    hole.moveTo(-halfInner, -halfInner);
    hole.lineTo(halfInner, -halfInner);
    hole.lineTo(halfInner, halfInner);
    hole.lineTo(-halfInner, halfInner);
    hole.closePath();
    outer.holes.push(hole);

    // One extruded ring = front cap + back cap + outer walls + inner walls,
    // all geometrically guaranteed to line up — this is what the old
    // hand-drawn-quad canvas code was trying (and failing) to fake.
    const frameGeo = new THREE.ExtrudeGeometry(outer, { depth: frameDepth, bevelEnabled: false, steps: 1 });
    const frameMat = new THREE.MeshStandardMaterial({ color: frameColor, roughness: 0.85, metalness: 0.02, side: THREE.DoubleSide });
    const frameMesh = new THREE.Mesh(frameGeo, frameMat);
    frameMesh.castShadow = true;
    frameMesh.receiveShadow = true;
    artGroup.add(frameMesh);
    disposables.push(frameGeo, frameMat);
  } else {
    // Flat frame: a single bordered plane sitting in front of the artwork.
    const outer = new THREE.Shape();
    outer.moveTo(-half, -half); outer.lineTo(half, -half); outer.lineTo(half, half); outer.lineTo(-half, half); outer.closePath();
    const hole = new THREE.Path();
    hole.moveTo(-halfInner, -halfInner); hole.lineTo(halfInner, -halfInner); hole.lineTo(halfInner, halfInner); hole.lineTo(-halfInner, halfInner); hole.closePath();
    outer.holes.push(hole);
    const flatGeo = new THREE.ShapeGeometry(outer);
    const flatMat = new THREE.MeshStandardMaterial({ color: frameColor, roughness: 0.9, side: THREE.DoubleSide });
    const flatMesh = new THREE.Mesh(flatGeo, flatMat);
    flatMesh.position.z = visibleLayers.length * layerDistance + 2;
    artGroup.add(flatMesh);
    disposables.push(flatGeo, flatMat);
  }

  // White backdrop behind the layers (matches the old "Art Container" bg)
  const backdropGeo = new THREE.PlaneGeometry(innerSize, innerSize);
  const backdropMat = new THREE.MeshStandardMaterial({ color: '#ffffff', roughness: 1 });
  const backdrop = new THREE.Mesh(backdropGeo, backdropMat);
  backdrop.position.z = -1;
  backdrop.receiveShadow = true;
  artGroup.add(backdrop);
  disposables.push(backdropGeo, backdropMat);

  // Each layer is a real plane at its own physical depth.
  visibleLayers.forEach(({ layer, texture }, index) => {
    if (!texture) return;
    const tex = new THREE.CanvasTexture(texture);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.needsUpdate = true;
    const geo = new THREE.PlaneGeometry(innerSize, innerSize);
    const mat = new THREE.MeshStandardMaterial({
      map: tex, transparent: true, alphaTest: 0.5, roughness: 0.95, side: THREE.DoubleSide,
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.z = index * layerDistance;
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    artGroup.add(mesh);
    disposables.push(geo, mat, tex);
  });

  // Lighting: In modern Three.js (r155+ PBR physical light units), diffuse reflection
  // is calculated as albedo / Math.PI. With the old light intensities (0.55 ambient
  // and ~0.85 directional), the total illuminance was only ~0.44 of full brightness,
  // causing the exported mockup, 3D frame, and SVG layers to look dim and dingy (~41% brightness).
  // To display full 100% brightness and vibrant colors matching the original SVG artwork,
  // total incident light (Ambient + Directional * NdotL) must equal Math.PI (~3.14159).
  const shadowStrength = (shadowOpacity / 100) * 0.85;
  const ambientIntensity = Math.PI * (1 - shadowStrength);
  scene.add(new THREE.AmbientLight('#ffffff', ambientIntensity));

  const topZ = Math.max(0, (visibleLayers.length - 1) * layerDistance);
  const dist = Math.max(layerDistance, 1);
  const angleX = Math.atan2(shadowY, dist);
  const angleY = Math.atan2(shadowX, dist);
  const lightDistance = 600;

  // Calculate N dot L (cosine of angle of incidence on front-facing Z-normal planes)
  const cosTheta = Math.max(0.2, Math.cos(angleX) * Math.cos(angleY));
  const directionalIntensity = (Math.PI * shadowStrength) / cosTheta;

  const key = new THREE.DirectionalLight('#ffffff', directionalIntensity);
  key.position.set(
    Math.sin(angleY) * lightDistance,
    -Math.sin(angleX) * lightDistance,
    topZ + Math.cos(angleX) * Math.cos(angleY) * lightDistance
  );
  key.target.position.set(0, 0, topZ);
  key.castShadow = true;
  key.shadow.mapSize.set(2048, 2048);
  key.shadow.radius = Math.max(1, shadowBlur);
  key.shadow.bias = -0.0005;
  key.shadow.normalBias = 0.05;
  key.shadow.camera.near = 1;
  key.shadow.camera.far = lightDistance * 2;
  // Dynamically scale shadow frustum with artScale and rotation diagonal so zoomed-in artwork never exceeds the shadow camera bounds
  const ext = BOX * Math.max(1, artScale) * 1.5;
  key.shadow.camera.left = -ext;
  key.shadow.camera.right = ext;
  key.shadow.camera.top = ext;
  key.shadow.camera.bottom = -ext;
  scene.add(key, key.target);

  const dispose = () => {
    disposables.forEach(d => d.dispose());
  };

  return { scene, camera, artGroup, dispose };
}

/** Render a built scene into a canvas at an arbitrary resolution. Reused for both the live preview and export/screenshot — same function, just a different size/pixelRatio. */
export function renderSceneToCanvas(
  renderer: THREE.WebGLRenderer,
  built: BuiltScene,
  width: number,
  height: number,
  pixelRatio: number
) {
  renderer.setPixelRatio(pixelRatio);
  renderer.setSize(width, height, false);
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.setClearColor(0x000000, 0);
  built.camera.aspect = width / height;
  built.camera.updateProjectionMatrix();
  renderer.render(built.scene, built.camera);
}

export function createRenderer(canvas?: HTMLCanvasElement) {
  const renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: true,
    alpha: true,
    preserveDrawingBuffer: true,
  });
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  return renderer;
}
