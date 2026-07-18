'use client';

import React, { useState, useEffect, useRef } from 'react';
import JSZip from 'jszip';
import { saveAs } from 'file-saver';
import * as opentype from 'opentype.js';
// paper.js is loaded lazily (client-only) because it expects a canvas/window
// and breaks Next.js SSR if imported at the top of the module.
let paperInstance: any = null;
async function getPaper() {
  if (paperInstance) return paperInstance;
  const paperModule = await import('paper');
  paperInstance = (paperModule as any).default ?? paperModule;
  return paperInstance;
}
import {
  Upload, Settings, Download, Image as ImageIcon,
  Layers, Plus, Trash2, GripVertical, ChevronRight,
  MoveRight, MoveDownRight, FileDown, Type, ArrowUpDown
} from 'lucide-react';

interface SvgLayer {
  id: string;
  file: File;
  content: string;
  color: string;
  name: string;
  opacity: number;
  width?: number;
  height?: number;
  viewBox?: string;
}

interface ShowcaseSettings {
  preset: string;
  spacingX: number;
  spacingY: number;
  scale: number;
  dropShadowBlur: number;
  dropShadowOffsetX: number;
  dropShadowOffsetY: number;
  dropShadowOpacity: number;
  backgroundColor: string;
  canvasWidth: number;
  canvasHeight: number;
}

interface WatermarkSettings {
  enabled: boolean;
  text: string;
  color: string;
  opacity: number;
  size: number;
  angle: number;
  gapX: number;
  gapY: number;
}

interface HeaderSettings {
  enabled: boolean;
  text: string;
  color: string;
  size: number;
  yPos: number;
}

interface PunchSettings {
  enabled: boolean;
  startNumber: number;
  xPos: number; // percentage or exact pixels from right/bottom
  yPos: number;
  align: 'right' | 'left' | 'center';
  baseline: 'bottom' | 'top' | 'middle';
  fontSize: number;
  fontFamily: string;
  color: string;
  mirror: boolean;
  // Real vector punching (requires a .ttf/.otf font at fontUrl, served from /public)
  fontUrl: string;
  // weld: union the number into the layer (raised/combined solid)
  // punch: subtract the number from the layer (cut a hole through it)
  // intersect: keep only where the number and the layer overlap
  mergeMode: 'weld' | 'punch' | 'intersect';
}

const DEFAULT_COLORS = [
  '#FDE68A', // Yellow
  '#F97316', // Orange
  '#DC2626', // Red
  '#78350F', // Dark Brown
  '#451A03', // Darker Brown
  '#000000', // Black
  '#FFFFFF', // White
  '#9CA3AF', // Gray
];

const extractColorFromName = (name: string): string | null => {
  const match = name.match(/(?:_|-)([a-fA-F0-9]{6})(?:_|-|\.svg|$)/i);
  if (match) {
    return `#${match[1].toLowerCase()}`;
  }
  return null;
};

const isValidHexColor = (color: string) => /^#(?:[0-9a-fA-F]{3}){1,2}$/.test(color);

const normalizeHexColor = (color: string) => {
  if (/^#[0-9a-fA-F]{3}$/.test(color)) {
    return '#' + color[1] + color[1] + color[2] + color[2] + color[3] + color[3];
  }
  return color;
};

const getSvgColor = (node: Element): string | null => {
  const fill = node.getAttribute('fill');
  if (fill && fill !== 'none' && fill !== 'transparent') {
    if (isValidHexColor(fill)) return normalizeHexColor(fill).toLowerCase();
  }
  
  const style = node.getAttribute('style');
  if (style) {
    const fillMatch = style.match(/fill:\s*([^;]+)/);
    if (fillMatch && fillMatch[1]) {
      const color = fillMatch[1].trim();
      if (color !== 'none' && color !== 'transparent') {
        if (isValidHexColor(color)) return normalizeHexColor(color).toLowerCase();
      }
    }
  }

  for (let i = 0; i < node.children.length; i++) {
    const childColor = getSvgColor(node.children[i]);
    if (childColor) return childColor;
  }
  return null;
};

const getLayerOffsets = (
  count: number,
  preset: string,
  spacingX: number,
  spacingY: number,
  baseW: number = 800,
  baseH: number = 800,
  scale: number = 1
) => {
  const offsets = [];
  let minX = 0, maxX = 0, minY = 0, maxY = 0;
  for (let i = 0; i < count; i++) {
    let x = 0;
    let y = 0;
    switch (preset) {
      case 'stacked': break;
      case 'horizontal': x = i * (baseW * scale + spacingX); break;
      case 'vertical': y = i * (baseH * scale + spacingY); break;
      case 'diagonal': x = i * spacingX; y = i * spacingY; break;
      case 'diagonal-reverse': x = -i * spacingX; y = i * spacingY; break;
      case 'zigzag-x': x = i * spacingX; y = (i % 2) * spacingY; break;
      case 'zigzag-y': x = (i % 2) * spacingX; y = i * spacingY; break;
      case 'circular':
        const angle = (i / Math.max(1, count)) * Math.PI * 2;
        x = Math.cos(angle) * spacingX * (count / 2);
        y = Math.sin(angle) * spacingY * (count / 2);
        break;
      case 'arch':
        x = i * spacingX;
        y = -Math.sin((i / Math.max(1, count - 1)) * Math.PI) * spacingY * 2;
        break;
      case 'wave':
        x = i * spacingX;
        y = Math.sin(i * 1.5) * spacingY;
        break;
      default:
        if (preset.startsWith('grid')) {
          let cols = 4; // default
          if (preset === 'grid-auto') {
            cols = Math.ceil(Math.sqrt(count));
          } else {
            const parsed = parseInt(preset.split('-')[1]);
            if (!isNaN(parsed)) cols = parsed;
          }
          const col = i % cols;
          const row = Math.floor(i / cols);
          x = col * (baseW * scale + spacingX);
          y = row * (baseH * scale + spacingY);
        }
        break;
    }
    offsets.push({ x, y });
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }
  return {
    offsets,
    totalWidth: maxX - minX,
    totalHeight: maxY - minY,
    minX,
    minY
  };
};

interface LayerRowProps {
  layer: SvgLayer;
  idx: number;
  layersCount: number;
  moveLayer: (index: number, direction: -1 | 1) => void;
  updateLayer: (id: string, updates: Partial<SvgLayer>) => void;
  removeLayer: (id: string) => void;
}

const LayerRow: React.FC<LayerRowProps> = ({
  layer,
  idx,
  layersCount,
  moveLayer,
  updateLayer,
  removeLayer,
}) => {
  const [hexInput, setHexInput] = useState(layer.color);

  useEffect(() => {
    setHexInput(layer.color);
  }, [layer.color]);

  const handleHexChange = (val: string) => {
    setHexInput(val);
    let cleanVal = val.trim();
    if (cleanVal && !cleanVal.startsWith('#')) {
      cleanVal = '#' + cleanVal;
    }
    if (isValidHexColor(cleanVal)) {
      updateLayer(layer.id, { color: normalizeHexColor(cleanVal).toLowerCase() });
    }
  };

  return (
    <div className="p-3 bg-white border border-gray-200 rounded-lg shadow-sm flex items-center group transition-shadow hover:shadow-md">
      <div className="flex flex-col mr-2 space-y-1">
        <button
          onClick={() => moveLayer(idx, -1)}
          disabled={idx === 0}
          className="text-gray-400 hover:text-gray-700 disabled:opacity-30"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 15l7-7 7 7" />
          </svg>
        </button>
        <button
          onClick={() => moveLayer(idx, 1)}
          disabled={idx === layersCount - 1}
          className="text-gray-400 hover:text-gray-700 disabled:opacity-30"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </button>
      </div>

      <div
        className="w-8 h-8 rounded shrink-0 mr-3 border border-gray-200 cursor-pointer overflow-hidden relative"
        style={{ backgroundColor: layer.color }}
      >
        <input
          type="color"
          value={layer.color}
          onChange={(e) => updateLayer(layer.id, { color: e.target.value })}
          className="absolute inset-0 opacity-0 cursor-pointer w-full h-full"
        />
      </div>

      <div className="flex-1 min-w-0 mr-2">
        <input
          type="text"
          value={layer.name}
          onChange={(e) => updateLayer(layer.id, { name: e.target.value })}
          className="w-full text-sm font-medium bg-transparent border-none p-0 focus:ring-0 truncate"
        />
        <div className="text-xs text-gray-500 mt-1">Layer {idx + 1}</div>
      </div>

      <div className="shrink-0 mr-2">
        <input
          type="text"
          value={hexInput}
          onChange={(e) => handleHexChange(e.target.value)}
          placeholder="#HEX"
          className="w-20 text-xs border border-gray-200 rounded px-2 py-1 text-center font-mono focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 bg-white text-gray-900"
        />
      </div>

      <button
        onClick={() => removeLayer(layer.id)}
        className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
      >
        <Trash2 className="w-4 h-4" />
      </button>
    </div>
  );
};

export default function App() {
  const [layers, setLayers] = useState<SvgLayer[]>([]);
  const [activeTab, setActiveTab] = useState<'layers' | 'showcase' | 'punch'>('layers');
  const [bulkColorsInput, setBulkColorsInput] = useState('');
  const [showcaseSettings, setShowcaseSettings] = useState<ShowcaseSettings>({
    preset: 'stacked',
    spacingX: 80,
    spacingY: 60,
    scale: 0.8,
    dropShadowBlur: 20,
    dropShadowOffsetX: 15,
    dropShadowOffsetY: 15,
    dropShadowOpacity: 0,
    backgroundColor: '#F3F4F6', // light gray
    canvasWidth: 3000,
    canvasHeight: 2250,
  });

  const [watermarkSettings, setWatermarkSettings] = useState<WatermarkSettings>({
    enabled: true,
    text: 'BetterCuts',
    color: '#000000',
    opacity: 0.25,
    size: 48,
    angle: -45,
    gapX: 300,
    gapY: 300,
  });

  const [headerSettings, setHeaderSettings] = useState<HeaderSettings>({
    enabled: false,
    text: 'My Layered Design',
    color: '#000000',
    size: 100,
    yPos: 100,
  });

  const [punchSettings, setPunchSettings] = useState<PunchSettings>({
    enabled: false,
    startNumber: 1,
    xPos: 20, // offset from edge
    yPos: 20,
    align: 'left',
    baseline: 'top',
    fontSize: 3000,
    fontFamily: 'Arial, sans-serif',
    color: '#000000',
    mirror: false,
    fontUrl: '/fonts/Inter-Bold.ttf',
    mergeMode: 'punch',
  });;

  // Cache the loaded opentype font so we don't re-fetch/parse it per layer/keystroke
  const fontRef = useRef<opentype.Font | null>(null);
  const fontUrlRef = useRef<string>('');
  const [mergedLayerIds, setMergedLayerIds] = useState<Set<string>>(new Set());
  const [isMerging, setIsMerging] = useState(false);

  const loadPunchFont = async (): Promise<opentype.Font | null> => {
    if (fontRef.current && fontUrlRef.current === punchSettings.fontUrl) {
      return fontRef.current;
    }
    try {
      const response = await fetch(punchSettings.fontUrl);
      if (!response.ok) {
        throw new Error(`Failed to fetch font: ${response.statusText}`);
      }
      const buffer = await response.arrayBuffer();
      const font = opentype.parse(buffer);
      fontRef.current = font;
      fontUrlRef.current = punchSettings.fontUrl;
      return font;
    } catch (err) {
      console.error('Failed to load punch font from', punchSettings.fontUrl, err);
      return null;
    }
  };

  const fileInputRef = useRef<HTMLInputElement>(null);
  const showcaseRef = useRef<HTMLDivElement>(null);
  const previewContainerRef = useRef<HTMLDivElement>(null);
  const [previewScale, setPreviewScale] = useState(0.2);

  const autoFitCanvas = (currentLayers = layers, preset = showcaseSettings.preset) => {
    if (currentLayers.length === 0) return;
    const baseW = currentLayers[0].width || 800;
    const baseH = currentLayers[0].height || 800;
    let bestScale = 1;
    
    // Auto fit math
    if (preset.startsWith('grid') || preset === 'horizontal' || preset === 'vertical') {
      // For these layouts we want them side-by-side with 5% padding
      const padX = showcaseSettings.canvasWidth * 0.05;
      const padY = showcaseSettings.canvasHeight * 0.05;
      const availW = showcaseSettings.canvasWidth - 2 * padX;
      const availH = showcaseSettings.canvasHeight - 2 * padY;
      
      let cols = currentLayers.length;
      let rows = 1;
      if (preset.startsWith('grid')) {
        cols = preset === 'grid-auto' ? Math.ceil(Math.sqrt(currentLayers.length)) : parseInt(preset.split('-')[1]) || 4;
        rows = Math.ceil(currentLayers.length / cols);
      } else if (preset === 'vertical') {
        cols = 1;
        rows = currentLayers.length;
      }

      // we assume spacing is a standard 40px
      const defaultGap = 40;
      const totalW_unscaled = cols * baseW + (cols - 1) * defaultGap;
      const totalH_unscaled = rows * baseH + (rows - 1) * defaultGap;

      const scaleX = availW / totalW_unscaled;
      const scaleY = availH / totalH_unscaled;
      bestScale = Math.min(scaleX, scaleY);

      setShowcaseSettings(s => ({ ...s, scale: bestScale, spacingX: defaultGap, spacingY: defaultGap }));
    } else {
      // For stacked, diagonal, circular, etc. just scale the first layer to fill most of the canvas
      const availW = showcaseSettings.canvasWidth * 0.7;
      const availH = showcaseSettings.canvasHeight * 0.7;
      bestScale = Math.min(availW / baseW, availH / baseH);
      setShowcaseSettings(s => ({ ...s, scale: bestScale }));
    }
  };

  useEffect(() => {
    if (!previewContainerRef.current) return;
    const observer = new ResizeObserver((entries) => {
      for (let entry of entries) {
        const { width, height } = entry.contentRect;
        const scaleX = (width - 64) / showcaseSettings.canvasWidth;
        const scaleY = (height - 64) / showcaseSettings.canvasHeight;
        setPreviewScale(Math.min(scaleX, scaleY));
      }
    });
    observer.observe(previewContainerRef.current);
    return () => observer.disconnect();
  }, [showcaseSettings.canvasWidth, showcaseSettings.canvasHeight]);

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    const fileList = Array.from(files).filter(
      (file) => file.type === 'image/svg+xml' || file.name.endsWith('.svg')
    );
    if (fileList.length === 0) return;

    let currentColorOffset = layers.length;
    const newLayersToAdd: SvgLayer[] = [];

    // Helper to read file as text
    const readFileAsText = (file: File): Promise<string> => {
      return new Promise((resolve) => {
        const reader = new FileReader();
        reader.onload = (event) => resolve((event.target?.result as string) || '');
        reader.readAsText(file);
      });
    };

    for (const file of fileList) {
      const content = await readFileAsText(file);
      if (!content) continue;

      const parser = new DOMParser();
      const doc = parser.parseFromString(content, 'image/svg+xml');
      const svgElement = doc.documentElement;

      let baseW = 800;
      let baseH = 800;
      const viewBox = svgElement.getAttribute('viewBox');
      if (viewBox) {
        const parts = viewBox.split(/[ ,]+/);
        if (parts.length >= 4) {
          baseW = parseFloat(parts[2]);
          baseH = parseFloat(parts[3]);
        }
      } else {
        baseW = parseFloat(svgElement.getAttribute('width') || '800');
        baseH = parseFloat(svgElement.getAttribute('height') || '800');
      }

      // Try to extract layers if a single SVG has multiple top-level elements
      const defsAndStyles = Array.from(svgElement.children).filter(el =>
        ['defs', 'style', 'title', 'desc'].includes(el.tagName.toLowerCase())
      );

      const potentialLayers = Array.from(svgElement.children).filter(el =>
        !['defs', 'style', 'title', 'desc'].includes(el.tagName.toLowerCase())
      );

      if (potentialLayers.length > 1) {
        // Split into multiple layers
        potentialLayers.forEach((child, childIndex) => {
          const newSvg = svgElement.cloneNode(false) as Element;
          defsAndStyles.forEach(def => newSvg.appendChild(def.cloneNode(true)));
          newSvg.appendChild(child.cloneNode(true));

          const layerName = child.getAttribute('id') || child.getAttribute('data-name') || `${file.name.replace('.svg', '')} - Layer ${childIndex + 1}`;
          const nameColor = extractColorFromName(layerName);
          const extractedColor = nameColor || getSvgColor(child);

          const newLayer: SvgLayer = {
            id: Math.random().toString(36).substring(7),
            file,
            content: new XMLSerializer().serializeToString(newSvg),
            color: extractedColor || DEFAULT_COLORS[currentColorOffset % DEFAULT_COLORS.length],
            name: layerName,
            opacity: 1,
            width: baseW,
            height: baseH,
            viewBox: viewBox || undefined,
          };
          currentColorOffset++;
          newLayersToAdd.push(newLayer);
        });
      } else {
        // Single layer
        const baseName = file.name.replace('.svg', '');
        const nameColor = extractColorFromName(baseName);
        const extractedColor = nameColor || getSvgColor(svgElement);
        const newLayer: SvgLayer = {
          id: Math.random().toString(36).substring(7),
          file,
          content,
          color: extractedColor || DEFAULT_COLORS[currentColorOffset % DEFAULT_COLORS.length],
          name: baseName,
          opacity: 1,
          width: baseW,
          height: baseH,
          viewBox: viewBox || undefined,
        };
        currentColorOffset++;
        newLayersToAdd.push(newLayer);
      }
    }

    if (newLayersToAdd.length > 0) {
      const updatedLayers = [...layers, ...newLayersToAdd];
      setLayers(updatedLayers);
      autoFitCanvas(updatedLayers);
    }

    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const removeLayer = (id: string) => {
    setLayers(layers.filter(l => l.id !== id));
  };

  const updateLayer = (id: string, updates: Partial<SvgLayer>) => {
    setLayers(layers.map(l => l.id === id ? { ...l, ...updates } : l));
  };

  const moveLayer = (index: number, direction: -1 | 1) => {
    if (index + direction < 0 || index + direction >= layers.length) return;
    const newLayers = [...layers];
    const temp = newLayers[index];
    newLayers[index] = newLayers[index + direction];
    newLayers[index + direction] = temp;
    setLayers(newLayers);
  };

  const handleBulkColorsChange = (value: string) => {
    setBulkColorsInput(value);
    const parts = value.split(',')
      .map(c => c.trim())
      .filter(c => c.length > 0);

    setLayers(prevLayers => 
      prevLayers.map((layer, idx) => {
        if (idx < parts.length) {
          let cleanVal = parts[idx];
          if (!cleanVal.startsWith('#')) {
            cleanVal = '#' + cleanVal;
          }
          if (isValidHexColor(cleanVal)) {
            return { ...layer, color: normalizeHexColor(cleanVal).toLowerCase() };
          }
        }
        return layer;
      })
    );
  };

  // Extract SVG content and inject color
  const processSvgContent = (content: string, color: string) => {
    const parser = new DOMParser();
    const doc = parser.parseFromString(content, 'image/svg+xml');
    const svgElement = doc.documentElement;

    // Attempt to set fill color to paths if they don't have one, or just set color on SVG wrapper
    // Ignore paths that are part of the punched number
    const elements = svgElement.querySelectorAll('path:not([data-punch="true"]), rect:not([data-punch="true"]), circle:not([data-punch="true"]), polygon:not([data-punch="true"]), polyline:not([data-punch="true"]), ellipse:not([data-punch="true"])');
    elements.forEach(p => {
      p.setAttribute('fill', color);
      p.removeAttribute('stroke');
    });

    return new XMLSerializer().serializeToString(svgElement);
  };

  // Compute the punch position for a given canvas size, shared by preview and vector merge.
  // minX/minY account for SVGs whose viewBox has a non-zero origin.
  const getPunchPosition = (w: number, h: number, minX = 0, minY = 0) => {
    let x = minX + punchSettings.xPos;
    let y = minY + punchSettings.yPos;
    if (punchSettings.align === 'right')   x = minX + w - punchSettings.xPos;
    else if (punchSettings.align === 'center') x = minX + w / 2;
    if (punchSettings.baseline === 'bottom') y = minY + h - punchSettings.yPos;
    else if (punchSettings.baseline === 'middle') y = minY + h / 2;
    else if (punchSettings.baseline === 'top')    y = minY + punchSettings.yPos;
    return { x, y };
  };

  // FAST LIVE-PREVIEW ONLY: overlays a real <text> element on top of the layer.
  // This is cheap enough to run every render, but it is NOT a real punch — the
  // text sits in its own layer above the artwork. Use handleMergePaths() to
  // actually weld/cut the number into the layer's geometry as one path.
  const punchNumberToSvg = (content: string, num: number) => {
    const parser = new DOMParser();
    const doc = parser.parseFromString(content, 'image/svg+xml');
    const svgElement = doc.documentElement;

    // Use getSvgSize so we get the viewBox origin (minX/minY) as well as dimensions
    const { w, h, minX, minY } = getSvgSize(svgElement);

    const textStr = num.toString();
    const { x, y } = getPunchPosition(w, h, minX, minY);

    // Inject @font-face so the preview uses the EXACT SAME font as the merge,
    // otherwise Arial vs Inter metrics will cause visual deviation.
    const fontName = 'PunchFontCustom';
    const defs = doc.createElementNS('http://www.w3.org/2000/svg', 'defs');
    const style = doc.createElementNS('http://www.w3.org/2000/svg', 'style');
    style.textContent = `
      @font-face {
        font-family: '${fontName}';
        src: url('${punchSettings.fontUrl}');
      }
    `;
    defs.appendChild(style);
    svgElement.insertBefore(defs, svgElement.firstChild);

    const textEl = doc.createElementNS('http://www.w3.org/2000/svg', 'text');
    textEl.textContent = textStr;
    textEl.setAttribute('x', x.toString());
    textEl.setAttribute('y', y.toString());
    textEl.setAttribute('font-family', fontName);
    textEl.setAttribute('font-size', punchSettings.fontSize.toString());
    textEl.setAttribute('font-weight', 'normal');
    textEl.setAttribute('fill', punchSettings.color);

    let anchor = punchSettings.align === 'right' ? 'end' : punchSettings.align === 'center' ? 'middle' : 'start';
    if (punchSettings.mirror) {
      if (anchor === 'start') anchor = 'end';
      else if (anchor === 'end') anchor = 'start';
    }

    textEl.setAttribute('text-anchor', anchor);
    textEl.setAttribute('dominant-baseline', punchSettings.baseline === 'bottom' ? 'alphabetic' : punchSettings.baseline === 'middle' ? 'middle' : 'hanging');
    textEl.setAttribute('data-punch', 'true');

    if (punchSettings.mirror) {
      textEl.setAttribute('transform', `matrix(-1, 0, 0, 1, ${2 * x}, 0)`);
    }

    svgElement.appendChild(textEl);
    return new XMLSerializer().serializeToString(svgElement);
  };

  // Get the layer's canvas size AND origin from viewBox (or width/height attrs).
  // Returns minX/minY so callers can correctly offset any absolute positions.
  const getSvgSize = (svgElement: Element): { w: number; h: number; minX: number; minY: number } => {
    let w = 1000, h = 1000, minX = 0, minY = 0;
    const viewBox = svgElement.getAttribute('viewBox');
    if (viewBox) {
      const parts = viewBox.split(/[ ,]+/);
      if (parts.length >= 4) {
        minX = parseFloat(parts[0]);
        minY = parseFloat(parts[1]);
        w    = parseFloat(parts[2]);
        h    = parseFloat(parts[3]);
      }
    } else {
      w = parseFloat(svgElement.getAttribute('width')  || '1000');
      h = parseFloat(svgElement.getAttribute('height') || '1000');
    }
    return { w, h, minX, minY };
  };

  // Build real vector outline path data for the number using opentype.js glyph
  // outlines (this is what makes a boolean op possible — you cannot union/
  // subtract a <text> element, only actual path geometry).
  //
  // IMPORTANT — coordinate system alignment:
  //   getPunchPosition() returns an (x, y) pair where:
  //     • For 'bottom' baseline: y = h - yPos  (alphabetic baseline, i.e. bottom of most letters)
  //     • For 'middle'  baseline: y = h / 2    (we want the visual mid-height of the glyphs here)
  //     • For 'top'     baseline: y = yPos      (we want the top of the cap-height here)
  //
  //   opentype's getPath(text, x, y, size) treats y as the ALPHABETIC baseline.
  //   So for 'bottom' we pass y as-is; for 'top'/'middle' we shift y downward
  //   by the cap-height (or half of it) so the visual top of the letter sits on
  //   the anchor point — exactly what SVG dominant-baseline="hanging"/"middle" does.
  const getNumberOutlinePathData = (
    font: opentype.Font,
    text: string,
    w: number,
    h: number,
    minX = 0,
    minY = 0
  ): string => {
    const { x, y } = getPunchPosition(w, h, minX, minY);
    const fontSize = punchSettings.fontSize;

    // Advance width for horizontal alignment (replicating text-anchor)
    const advanceWidth = font.getAdvanceWidth(text, fontSize);

    let originX = x;
    if (punchSettings.align === 'right') originX = x - advanceWidth;
    else if (punchSettings.align === 'center') originX = x - advanceWidth / 2;

    // Cap-height is the most reliable proxy for "top of a capital letter",
    // which is what SVG dominant-baseline="hanging" visually aligns to.
    // Many fonts expose it directly; fall back to 70 % of the UPM if absent.
    const capHeight = font.tables?.os2?.sCapHeight
      ? (font.tables.os2.sCapHeight / font.unitsPerEm) * fontSize
      : (font.ascender / font.unitsPerEm) * fontSize * 0.70;

    let originY = y; // default: 'bottom' — alphabetic baseline matches directly
    if (punchSettings.baseline === 'top') {
      // Shift the alphabetic baseline DOWN by cap-height so the top of the
      // glyph sits at y (matching dominant-baseline="hanging")
      originY = y + capHeight;
    } else if (punchSettings.baseline === 'middle') {
      // Shift DOWN by half the cap-height so the visual midpoint is at y
      // (matching dominant-baseline="middle" for capital letters)
      originY = y + capHeight / 2;
    }

    const glyphPath = font.getPath(text, originX, originY, fontSize);
    // Mirroring is applied via a transform attribute on the wrapping SVG element
    // in mergeNumberIntoLayer — NOT baked into the path data itself.
    return glyphPath.toPathData(3);
  };

  // Recursively collect every leaf Path / CompoundPath inside a paper.js item
  // tree (importSVG wraps everything in Layer > Group > … > Path, so we can't
  // assume direct children are PathItems).
  const collectLeafPaths = (item: any): any[] => {
    // Path and CompoundPath are the only types that have boolean-op methods
    if (item.className === 'Path' || item.className === 'CompoundPath') {
      return [item];
    }
    if (item.children && item.children.length) {
      const paths: any[] = [];
      for (const child of item.children) {
        paths.push(...collectLeafPaths(child));
      }
      return paths;
    }
    return [];
  };

  // Convert an SVG markup string into a single united paper.js PathItem that
  // is ready for boolean operations (unite / subtract / intersect).
  const svgToPaperPathItem = (svgMarkup: string, paperScope: any): any | null => {
    const rootItem = paperScope.project.importSVG(svgMarkup, { expandShapes: true, insert: false });
    if (!rootItem) return null;

    const paths = collectLeafPaths(rootItem);
    if (paths.length === 0) return null;

    // Unite all leaf paths into one compound shape
    let combined: any = paths[0];
    for (let i = 1; i < paths.length; i++) {
      combined = combined.unite(paths[i], { insert: false });
    }
    return combined;
  };

  // THE REAL MERGE: converts the number to glyph outlines, then performs an
  // actual boolean path operation (union/subtract/intersect) against the
  // layer's existing shape(s), producing a single combined <path> — this is
  // what makes the number actually "punched"/welded into the layer instead
  // of sitting on top of it as a separate object.
  const mergeNumberIntoLayer = async (
    layer: SvgLayer,
    num: number,
    font: opentype.Font
  ): Promise<string> => {
    const parser = new DOMParser();
    const doc = parser.parseFromString(layer.content, 'image/svg+xml');
    const svgElement = doc.documentElement;
    const { w, h, minX, minY } = getSvgSize(svgElement);
    const textStr = num.toString();

    const numberPathData = getNumberOutlinePathData(font, textStr, w, h, minX, minY);
    const { x: anchorX } = getPunchPosition(w, h, minX, minY);
    const mirrorTransform = punchSettings.mirror
      ? ` transform="matrix(-1,0,0,1,${2 * anchorX},0)"`
      : '';

    const paper = await getPaper();

    // Create a fresh offscreen canvas + project per merge so state from a
    // previous layer or previous call doesn't bleed into this one.
    const canvas = document.createElement('canvas');
    canvas.width = Math.max(1, w);
    canvas.height = Math.max(1, h);
    paper.setup(canvas);

    try {
      // Import the layer artwork into paper.js and flatten to a single PathItem
      const layerSvgString = new XMLSerializer().serializeToString(svgElement);
      const layerShape = svgToPaperPathItem(layerSvgString, paper);
      if (!layerShape) throw new Error('Could not import layer geometry into paper.js — no drawable paths found.');

      // Build the number outline SVG and flatten it to a single PathItem
      const numberSvgString = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}"><path d="${numberPathData}"${mirrorTransform} /></svg>`;
      const numberShape = svgToPaperPathItem(numberSvgString, paper);
      if (!numberShape) throw new Error('Could not import number outline into paper.js.');

      let result: any;
      if (punchSettings.mergeMode === 'weld') {
        result = layerShape.unite(numberShape, { insert: false });
      } else if (punchSettings.mergeMode === 'intersect') {
        result = layerShape.intersect(numberShape, { insert: false });
      } else {
        // 'punch' — cut the number out of the layer, leaving a hole
        result = layerShape.subtract(numberShape, { insert: false });
      }

      const mergedPathData = result.pathData;
      if (!mergedPathData) throw new Error('Boolean operation produced no path data.');

      // Preserve all original <svg> attributes (like preserveAspectRatio, width="100%", etc.)
      // by clearing the old children and appending our single merged path.
      while (svgElement.firstChild) {
        svgElement.removeChild(svgElement.firstChild);
      }

      const mergedPath = doc.createElementNS('http://www.w3.org/2000/svg', 'path');
      mergedPath.setAttribute('d', mergedPathData);
      mergedPath.setAttribute('fill', layer.color);
      mergedPath.setAttribute('data-merged', 'true');
      svgElement.appendChild(mergedPath);

      return new XMLSerializer().serializeToString(svgElement);
    } finally {
      paper.project.clear();
    }
  };

  // Runs the real merge across every layer and writes the result back into
  // layer.content, so preview + every export path from then on uses the
  // single combined path instead of the text overlay.
  const handleMergePaths = async () => {
    if (layers.length === 0) return;
    setIsMerging(true);
    try {
      const font = await loadPunchFont();
      if (!font) {
        alert(
          `Couldn't load the punch font from "${punchSettings.fontUrl}". ` +
          `Add a .ttf/.otf file at that path under /public (e.g. /public/fonts/Inter-Bold.ttf) ` +
          `and make sure the Punch tab's Font URL points to it.`
        );
        return;
      }

      const newLayers = [...layers];
      const newMerged = new Set(mergedLayerIds);
      for (let i = 0; i < newLayers.length; i++) {
        const layer = newLayers[i];
        const num = punchSettings.startNumber + i;
        const mergedContent = await mergeNumberIntoLayer(layer, num, font);
        newLayers[i] = { ...layer, content: mergedContent };
        newMerged.add(layer.id);
      }
      setLayers(newLayers);
      setMergedLayerIds(newMerged);
    } catch (err) {
      console.error('Merge Paths failed:', err);
      alert('Merge Paths failed — see console for details.');
    } finally {
      setIsMerging(false);
    }
  };

  const handleExportShowcase = () => {
    if (!showcaseRef.current) return;

    // We will draw the showcase DOM to a canvas, or create a large SVG and download it.
    // Since rendering HTML to Canvas reliably requires html2canvas which can be heavy/buggy with SVGs,
    // let's construct a massive SVG containing all our SVGs as <g> tags and export that, OR 
    // rely on a simpler canvas drawing approach by drawing SVGs to Canvas.

    const canvas = document.createElement('canvas');
    canvas.width = showcaseSettings.canvasWidth;
    canvas.height = showcaseSettings.canvasHeight;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Fill background
    ctx.fillStyle = showcaseSettings.backgroundColor;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Calculate bounding box of all layers to center them
    const layersCount = layers.length;
    const baseW = layers[0]?.width || 800;
    const baseH = layers[0]?.height || 800;

    const layout = getLayerOffsets(layersCount, showcaseSettings.preset, showcaseSettings.spacingX, showcaseSettings.spacingY, baseW, baseH, showcaseSettings.scale);

    let imagesLoaded = layers.map((layer, index) => {
      return new Promise<{ img: HTMLImageElement, xOff: number, yOff: number, drawW: number, drawH: number, opacity: number, w: number, h: number }>((resolve) => {
        let xOff = layout.offsets[index].x;
        let yOff = layout.offsets[index].y;

        const img = new Image();

        // Ensure SVG has explicit width and height for canvas rendering
        const parser = new DOMParser();
        const doc = parser.parseFromString(layer.content, 'image/svg+xml');
        const svgElement = doc.documentElement;
        let w = layer.width || 800;
        let h = layer.height || 800;
        svgElement.setAttribute('width', w.toString());
        svgElement.setAttribute('height', h.toString());
        const contentWithDims = new XMLSerializer().serializeToString(svgElement);

        // Add punch numbers if enabled (skip if this layer was already vector-merged)
        let finalContent = contentWithDims;
        if (punchSettings.enabled && !mergedLayerIds.has(layer.id)) {
          finalContent = punchNumberToSvg(finalContent, punchSettings.startNumber + index);
        }

        const svgContent = processSvgContent(finalContent, layer.color);
        const url = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svgContent);

        img.onload = () => {
          const drawW = w * showcaseSettings.scale;
          const drawH = h * showcaseSettings.scale;
          resolve({ img, xOff, yOff, drawW, drawH, opacity: layer.opacity, w, h });
        };
        img.src = url;
      });
    });

    Promise.all(imagesLoaded).then((loadedImages) => {
      const drawFirst = loadedImages[0];
      const startX = (canvas.width - layout.totalWidth - (drawFirst ? drawFirst.drawW : 800)) / 2 - layout.minX;
      const startY = (canvas.height - layout.totalHeight - (drawFirst ? drawFirst.drawH : 800)) / 2 - layout.minY;

      // Draw in normal order (0 is bottom, highest index is top)
      for (let i = 0; i < loadedImages.length; i++) {
        const item = loadedImages[i];
        ctx.save();
        // Drop shadow
        ctx.shadowColor = `rgba(0,0,0,${showcaseSettings.dropShadowOpacity})`;
        ctx.shadowBlur = showcaseSettings.dropShadowBlur;
        ctx.shadowOffsetX = showcaseSettings.dropShadowOffsetX;
        ctx.shadowOffsetY = showcaseSettings.dropShadowOffsetY;

        ctx.globalAlpha = item.opacity;
        ctx.drawImage(item.img, startX + item.xOff, startY + item.yOff, item.drawW, item.drawH);
        ctx.restore();
      }

      // Draw Watermark
      if (watermarkSettings.enabled && watermarkSettings.text) {
        ctx.save();
        ctx.globalAlpha = watermarkSettings.opacity;
        ctx.fillStyle = watermarkSettings.color;
        ctx.font = `bold ${watermarkSettings.size}px Arial, sans-serif`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        
        const angleRad = (watermarkSettings.angle * Math.PI) / 180;
        const diag = Math.sqrt(canvas.width * canvas.width + canvas.height * canvas.height);
        const stepsX = Math.ceil(diag / watermarkSettings.gapX) * 2;
        const stepsY = Math.ceil(diag / watermarkSettings.gapY) * 2;
        
        ctx.translate(canvas.width / 2, canvas.height / 2);
        ctx.rotate(angleRad);
        
        for (let ix = -stepsX; ix <= stepsX; ix++) {
          for (let iy = -stepsY; iy <= stepsY; iy++) {
            ctx.fillText(watermarkSettings.text, ix * watermarkSettings.gapX, iy * watermarkSettings.gapY);
          }
        }
        ctx.restore();
      }

      // Draw Header Title
      if (headerSettings.enabled && headerSettings.text) {
        ctx.save();
        ctx.fillStyle = headerSettings.color;
        ctx.font = `bold ${headerSettings.size}px Arial, sans-serif`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'top';
        ctx.fillText(headerSettings.text, canvas.width / 2, headerSettings.yPos);
        ctx.restore();
      }

      canvas.toBlob((blob) => {
        if (blob) {
          saveAs(blob, 'showcase.png');
        }
      }, 'image/png');
    });
  };

  const handleExportCombinedSvg = () => {
    if (layers.length === 0) return;

    // Union bounding box across ALL layers' own viewBoxes, instead of trusting
    // only layers[0]. Previously every layer's raw coordinates were dumped
    // into layers[0]'s viewBox alone, so any layer whose source file had a
    // different width/height/viewBox got silently cropped or shifted — which
    // is why the exported combined SVG didn't match the originals. Layer
    // coordinates already live in a shared absolute space (that's what makes
    // a layer stack register correctly), so we don't need to transform each
    // layer — we just need a canvas big enough to show all of them.
    let unionMinX = Infinity, unionMinY = Infinity, unionMaxX = -Infinity, unionMaxY = -Infinity;
    layers.forEach((layer) => {
      let vbX = 0, vbY = 0, vbW = layer.width || 800, vbH = layer.height || 800;
      if (layer.viewBox) {
        const parts = layer.viewBox.split(/[ ,]+/).map(parseFloat);
        if (parts.length >= 4) [vbX, vbY, vbW, vbH] = parts;
      }
      unionMinX = Math.min(unionMinX, vbX);
      unionMinY = Math.min(unionMinY, vbY);
      unionMaxX = Math.max(unionMaxX, vbX + vbW);
      unionMaxY = Math.max(unionMaxY, vbY + vbH);
    });
    const unionW = unionMaxX - unionMinX;
    const unionH = unionMaxY - unionMinY;

    const firstLayerDoc = new DOMParser().parseFromString(layers[0].content, 'image/svg+xml');
    const firstRoot = firstLayerDoc.documentElement;

    const combinedSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    combinedSvg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');

    if (firstRoot.hasAttribute('preserveAspectRatio')) {
      combinedSvg.setAttribute('preserveAspectRatio', firstRoot.getAttribute('preserveAspectRatio')!);
    }

    combinedSvg.setAttribute('viewBox', `${unionMinX} ${unionMinY} ${unionW} ${unionH}`);

    layers.forEach((layer, index) => {
      let finalContent = layer.content;
      const alreadyMerged = mergedLayerIds.has(layer.id);
      if (punchSettings.enabled && !alreadyMerged) {
        finalContent = punchNumberToSvg(finalContent, punchSettings.startNumber + index);
      }
      finalContent = processSvgContent(finalContent, layer.color);

      const parser = new DOMParser();
      const doc = parser.parseFromString(finalContent, 'image/svg+xml');
      const root = doc.documentElement;

      const g = document.createElementNS('http://www.w3.org/2000/svg', 'g');
      g.setAttribute('id', layer.name.replace(/[^a-zA-Z0-9_-]/g, '_'));

      while (root.firstChild) {
        g.appendChild(root.firstChild);
      }

      combinedSvg.appendChild(g);
    });

    let svgString = new XMLSerializer().serializeToString(combinedSvg);
    svgString = '<?xml version="1.0" encoding="utf-8"?>\n' + svgString;

    const blob = new Blob([svgString], { type: 'image/svg+xml;charset=utf-8' });
    saveAs(blob, 'combined_layers.svg');
  };

  const handleDownloadPunchedSvgs = async () => {
    const zip = new JSZip();

    layers.forEach((layer, idx) => {
      const num = punchSettings.startNumber + idx;
      const alreadyMerged = mergedLayerIds.has(layer.id);
      const punchedContent = (punchSettings.enabled && !alreadyMerged) ? punchNumberToSvg(layer.content, num) : layer.content;
      zip.file(`${layer.name}_layer${num}.svg`, punchedContent);
    });

    const content = await zip.generateAsync({ type: 'blob' });
    saveAs(content, 'punched_layers.zip');
  };

  return (
    <div className="flex h-screen bg-gray-50 text-gray-900 overflow-hidden font-sans" suppressHydrationWarning>
      {/* Sidebar */}
      <div className="w-80 bg-white border-r border-gray-200 flex flex-col shadow-sm z-10 shrink-0">
        <div className="p-4 border-b border-gray-200 bg-white">
          <h1 className="text-xl font-semibold tracking-tight">Layer Showcase</h1>
          <p className="text-sm text-gray-500 mt-1">Export 3D layered presentations</p>
        </div>

        {/* Shortcut Toggles */}
        <div className="px-4 py-2.5 border-b border-gray-200 bg-gray-50 flex items-center justify-between gap-2 text-xs">
          <button
            onClick={() => setHeaderSettings(prev => ({ ...prev, enabled: !prev.enabled }))}
            className={`flex-1 py-1.5 px-2 rounded-md font-medium border transition-all flex items-center justify-center gap-1.5 ${
              headerSettings.enabled
                ? 'bg-blue-50 border-blue-200 text-blue-700 shadow-sm'
                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-100 hover:text-gray-900'
            }`}
          >
            <span>Header</span>
            <span className={`w-2 h-2 rounded-full transition-colors ${headerSettings.enabled ? 'bg-blue-600' : 'bg-gray-300'}`} />
          </button>

          <button
            onClick={() => {
              const nextEnabled = !watermarkSettings.enabled;
              setWatermarkSettings(prev => ({
                ...prev,
                enabled: nextEnabled,
                text: nextEnabled ? `${layers.length} Layers` : prev.text
              }));
            }}
            className={`flex-1 py-1.5 px-2 rounded-md font-medium border transition-all flex items-center justify-center gap-1.5 ${
              watermarkSettings.enabled
                ? 'bg-blue-50 border-blue-200 text-blue-700 shadow-sm'
                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-100 hover:text-gray-900'
            }`}
          >
            <span>Watermark</span>
            <span className={`w-2 h-2 rounded-full transition-colors ${watermarkSettings.enabled ? 'bg-blue-600' : 'bg-gray-300'}`} />
          </button>

          <button
            onClick={() => setPunchSettings(prev => ({ ...prev, enabled: !prev.enabled }))}
            className={`flex-1 py-1.5 px-2 rounded-md font-medium border transition-all flex items-center justify-center gap-1.5 ${
              punchSettings.enabled
                ? 'bg-purple-50 border-purple-200 text-purple-700 shadow-sm'
                : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-100 hover:text-gray-900'
            }`}
          >
            <span>Punch</span>
            <span className={`w-2 h-2 rounded-full transition-colors ${punchSettings.enabled ? 'bg-purple-600' : 'bg-gray-300'}`} />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-gray-200 text-sm">
          <button
            className={`flex-1 py-3 font-medium transition-colors ${activeTab === 'layers' ? 'text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:text-gray-900'}`}
            onClick={() => setActiveTab('layers')}
          >
            <Layers className="w-4 h-4 mx-auto mb-1" />
            Layers
          </button>
          <button
            className={`flex-1 py-3 font-medium transition-colors ${activeTab === 'showcase' ? 'text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:text-gray-900'}`}
            onClick={() => setActiveTab('showcase')}
          >
            <ImageIcon className="w-4 h-4 mx-auto mb-1" />
            Showcase
          </button>
          <button
            className={`flex-1 py-3 font-medium transition-colors ${activeTab === 'punch' ? 'text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:text-gray-900'}`}
            onClick={() => setActiveTab('punch')}
          >
            <Type className="w-4 h-4 mx-auto mb-1" />
            Punch
          </button>
        </div>

        {/* Sidebar Content */}
        <div className="flex-1 overflow-y-auto p-4 custom-scrollbar">
          {activeTab === 'layers' && (
            <div className="space-y-4">
              <input
                type="file"
                multiple
                accept=".svg"
                className="hidden"
                ref={fileInputRef}
                onChange={handleFileUpload}
              />
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-sm font-semibold text-gray-900">Stack Order</h3>
                <button
                  onClick={() => setLayers([...layers].reverse())}
                  disabled={layers.length < 2}
                  className="text-xs text-blue-600 hover:text-blue-800 flex items-center disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <ArrowUpDown className="w-3 h-3 mr-1" />
                  Reverse
                </button>
              </div>

              {/* Paste bulk colors input bar */}
              <div className="bg-gray-50 border border-gray-200 rounded-lg p-3 space-y-1.5">
                <label className="block text-xs font-semibold text-gray-700">
                  Bulk Color Palette (Comma-separated HEX)
                </label>
                <input
                  type="text"
                  value={bulkColorsInput}
                  onChange={(e) => handleBulkColorsChange(e.target.value)}
                  placeholder="e.g. #9d7769, #b4733b, #efcca9"
                  className="w-full text-xs border border-gray-200 rounded px-2.5 py-1.5 font-mono focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 bg-white text-gray-900 placeholder-gray-400"
                />
              </div>
              <button
                onClick={() => fileInputRef.current?.click()}
                className="w-full py-3 px-4 bg-white border-2 border-dashed border-gray-300 rounded-lg text-gray-600 hover:border-blue-500 hover:bg-blue-50 transition-colors flex items-center justify-center font-medium shadow-sm"
              >
                <Upload className="w-4 h-4 mr-2" />
                Upload SVGs
              </button>

              <div className="space-y-2 mt-4">
                {layers.map((layer, idx) => (
                  <LayerRow
                    key={layer.id}
                    layer={layer}
                    idx={idx}
                    layersCount={layers.length}
                    moveLayer={moveLayer}
                    updateLayer={updateLayer}
                    removeLayer={removeLayer}
                  />
                ))}

                {layers.length === 0 && (
                  <div className="text-center py-10 text-gray-400 text-sm">
                    No layers added yet.<br />Upload SVG files to get started.
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === 'showcase' && (
            <div className="space-y-6">
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="block text-sm font-medium text-gray-700">Preset Layout</label>
                  <button
                    onClick={() => autoFitCanvas()}
                    className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded hover:bg-blue-200 transition-colors font-medium"
                  >
                    Auto Fit Canvas
                  </button>
                </div>
                <select
                  value={showcaseSettings.preset}
                  onChange={(e) => setShowcaseSettings({ ...showcaseSettings, preset: e.target.value })}
                  className="w-full p-2 border border-gray-300 rounded text-sm focus:ring-blue-500 focus:border-blue-500 bg-white"
                >
                  <option value="stacked">Stacked</option>
                  <option value="horizontal">Horizontal</option>
                  <option value="vertical">Vertical</option>
                  <option value="diagonal">Diagonal (Top-Left to Bottom-Right)</option>
                  <option value="diagonal-reverse">Diagonal Reverse (Top-Right to Bottom-Left)</option>
                  <option value="zigzag-x">Zigzag Horizontal</option>
                  <option value="zigzag-y">Zigzag Vertical</option>
                  <option value="circular">Circular / Ring</option>
                  <option value="arch">Arch / Bridge</option>
                  <option value="wave">Sine Wave</option>
                  <option value="grid-auto">Grid (Auto)</option>
                  <option value="grid-2">Grid (2 columns)</option>
                  <option value="grid-3">Grid (3 columns)</option>
                  <option value="grid-4">Grid (4 columns)</option>
                  <option value="grid-5">Grid (5 columns)</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1 flex justify-between">
                  <span>Scale</span>
                  <span className="text-gray-500">{showcaseSettings.scale.toFixed(2)}x</span>
                </label>
                <input
                  type="range" min="0.1" max="2" step="0.05"
                  value={showcaseSettings.scale}
                  onChange={(e) => setShowcaseSettings({ ...showcaseSettings, scale: parseFloat(e.target.value) })}
                  className="w-full accent-blue-600"
                />
              </div>

              {showcaseSettings.preset !== 'stacked' && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1 flex justify-between">
                      <span>X Spacing</span>
                      <span className="text-gray-500">{showcaseSettings.spacingX}px</span>
                    </label>
                    <input
                      type="range" min="0" max="300" step="10"
                      value={showcaseSettings.spacingX}
                      onChange={(e) => setShowcaseSettings({ ...showcaseSettings, spacingX: parseInt(e.target.value) })}
                      className="w-full accent-blue-600"
                    />
                  </div>

                  {showcaseSettings.preset === 'diagonal' && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1 flex justify-between">
                        <span>Y Spacing</span>
                        <span className="text-gray-500">{showcaseSettings.spacingY}px</span>
                      </label>
                      <input
                        type="range" min="-100" max="300" step="10"
                        value={showcaseSettings.spacingY}
                        onChange={(e) => setShowcaseSettings({ ...showcaseSettings, spacingY: parseInt(e.target.value) })}
                        className="w-full accent-blue-600"
                      />
                    </div>
                  )}
                </>
              )}

              <div className="pt-4 border-t border-gray-100">
                <h3 className="text-sm font-semibold text-gray-900 mb-3">Drop Shadow</h3>
                <div className="space-y-4">
                  <div>
                    <label className="block text-xs text-gray-500 mb-1">Blur Radius</label>
                    <input type="range" min="0" max="100" value={showcaseSettings.dropShadowBlur} onChange={(e) => setShowcaseSettings({ ...showcaseSettings, dropShadowBlur: parseInt(e.target.value) })} className="w-full accent-gray-600" />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-500 mb-1">Offset X</label>
                    <input type="range" min="-50" max="50" value={showcaseSettings.dropShadowOffsetX} onChange={(e) => setShowcaseSettings({ ...showcaseSettings, dropShadowOffsetX: parseInt(e.target.value) })} className="w-full accent-gray-600" />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-500 mb-1">Offset Y</label>
                    <input type="range" min="-50" max="50" value={showcaseSettings.dropShadowOffsetY} onChange={(e) => setShowcaseSettings({ ...showcaseSettings, dropShadowOffsetY: parseInt(e.target.value) })} className="w-full accent-gray-600" />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-500 mb-1">Opacity</label>
                    <input type="range" min="0" max="1" step="0.05" value={showcaseSettings.dropShadowOpacity} onChange={(e) => setShowcaseSettings({ ...showcaseSettings, dropShadowOpacity: parseFloat(e.target.value) })} className="w-full accent-gray-600" />
                  </div>
                </div>

                <label className="flex items-center space-x-3 cursor-pointer p-3 border border-gray-200 rounded hover:bg-gray-50 mt-4">
                  <input type="checkbox" checked={punchSettings.mirror} onChange={(e) => setPunchSettings({ ...punchSettings, mirror: e.target.checked })} className="w-4 h-4 text-blue-600 rounded" />
                  <span className="text-sm font-medium text-gray-900">Mirror Horizontally (for back-cutting)</span>
                </label>
              </div>

              <div className="pt-4 border-t border-gray-100">
                <label className="block text-sm font-medium text-gray-700 mb-2">Background Color</label>
                <div className="flex gap-2">
                  <input
                    type="color"
                    value={showcaseSettings.backgroundColor}
                    onChange={(e) => setShowcaseSettings({ ...showcaseSettings, backgroundColor: e.target.value })}
                    className="w-10 h-10 rounded border border-gray-200 p-0 cursor-pointer"
                  />
                  <input
                    type="text"
                    value={showcaseSettings.backgroundColor}
                    onChange={(e) => setShowcaseSettings({ ...showcaseSettings, backgroundColor: e.target.value })}
                    className="flex-1 text-sm border border-gray-200 rounded px-2"
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-gray-100">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-semibold text-gray-900">Header Title</h3>
                  <div className="relative inline-block w-10 align-middle select-none transition duration-200 ease-in">
                    <input type="checkbox" name="hdr-toggle" id="hdr-toggle" className="toggle-checkbox absolute block w-5 h-5 rounded-full bg-white border-4 appearance-none cursor-pointer transition-transform duration-200 ease-in-out checked:translate-x-5 checked:border-blue-600" checked={headerSettings.enabled} onChange={(e) => setHeaderSettings({ ...headerSettings, enabled: e.target.checked })} />
                    <label htmlFor="hdr-toggle" className="toggle-label block overflow-hidden h-5 rounded-full bg-gray-300 cursor-pointer"></label>
                  </div>
                </div>
                
                <div className={`space-y-4 ${!headerSettings.enabled ? 'opacity-50 pointer-events-none' : ''}`}>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Text</label>
                    <input type="text" value={headerSettings.text} onChange={(e) => setHeaderSettings({ ...headerSettings, text: e.target.value })} className="w-full p-2 border border-gray-300 rounded text-sm focus:ring-blue-500 focus:border-blue-500" />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Color</label>
                      <div className="flex h-[38px]">
                        <input type="color" value={headerSettings.color} onChange={(e) => setHeaderSettings({ ...headerSettings, color: e.target.value })} className="w-10 h-full border border-gray-300 rounded-l p-0 cursor-pointer" />
                        <input type="text" value={headerSettings.color} onChange={(e) => setHeaderSettings({ ...headerSettings, color: e.target.value })} className="flex-1 w-full p-2 border border-gray-300 border-l-0 rounded-r text-sm focus:ring-blue-500 focus:border-blue-500" />
                      </div>
                    </div>
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">Size</label>
                      <input type="range" min="20" max="400" value={headerSettings.size} onChange={(e) => setHeaderSettings({ ...headerSettings, size: parseInt(e.target.value) })} className="w-full accent-gray-600 mt-2" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs text-gray-500 mb-1 flex justify-between">
                      <span>Top Margin</span>
                      <span className="text-gray-500">{headerSettings.yPos}px</span>
                    </label>
                    <input type="range" min="0" max="1000" step="10" value={headerSettings.yPos} onChange={(e) => setHeaderSettings({ ...headerSettings, yPos: parseInt(e.target.value) })} className="w-full accent-gray-600" />
                  </div>
                </div>
              </div>

              <div className="pt-4 border-t border-gray-100">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-semibold text-gray-900">Watermark</h3>
                  <div className="relative inline-block w-10 align-middle select-none transition duration-200 ease-in">
                    <input
                      type="checkbox"
                      name="wm-toggle"
                      id="wm-toggle"
                      className="toggle-checkbox absolute block w-5 h-5 rounded-full bg-white border-4 appearance-none cursor-pointer transition-transform duration-200 ease-in-out checked:translate-x-5 checked:border-blue-600"
                      checked={watermarkSettings.enabled}
                      onChange={(e) => {
                        const isEnabled = e.target.checked;
                        setWatermarkSettings({
                          ...watermarkSettings,
                          enabled: isEnabled,
                          text: isEnabled ? `${layers.length} Layers` : watermarkSettings.text
                        });
                      }}
                    />
                    <label htmlFor="wm-toggle" className="toggle-label block overflow-hidden h-5 rounded-full bg-gray-300 cursor-pointer"></label>
                  </div>
                </div>
                
                <div className={`space-y-4 ${!watermarkSettings.enabled ? 'opacity-50 pointer-events-none' : ''}`}>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Text</label>
                    <input type="text" value={watermarkSettings.text} onChange={(e) => setWatermarkSettings({ ...watermarkSettings, text: e.target.value })} className="w-full p-2 border border-gray-300 rounded text-sm focus:ring-blue-500 focus:border-blue-500" />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Color</label>
                      <div className="flex h-[38px]">
                        <input type="color" value={watermarkSettings.color} onChange={(e) => setWatermarkSettings({ ...watermarkSettings, color: e.target.value })} className="w-10 h-full border border-gray-300 rounded-l p-0 cursor-pointer" />
                        <input type="text" value={watermarkSettings.color} onChange={(e) => setWatermarkSettings({ ...watermarkSettings, color: e.target.value })} className="flex-1 w-full p-2 border border-gray-300 border-l-0 rounded-r text-sm focus:ring-blue-500 focus:border-blue-500" />
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Opacity</label>
                      <input type="range" min="0.05" max="1" step="0.05" value={watermarkSettings.opacity} onChange={(e) => setWatermarkSettings({ ...watermarkSettings, opacity: parseFloat(e.target.value) })} className="w-full accent-blue-600 mt-2" />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">Size</label>
                      <input type="range" min="10" max="200" value={watermarkSettings.size} onChange={(e) => setWatermarkSettings({ ...watermarkSettings, size: parseInt(e.target.value) })} className="w-full accent-gray-600" />
                    </div>
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">Angle</label>
                      <input type="range" min="-90" max="90" value={watermarkSettings.angle} onChange={(e) => setWatermarkSettings({ ...watermarkSettings, angle: parseInt(e.target.value) })} className="w-full accent-gray-600" />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">Spacing X</label>
                      <input type="range" min="50" max="1000" step="10" value={watermarkSettings.gapX} onChange={(e) => setWatermarkSettings({ ...watermarkSettings, gapX: parseInt(e.target.value) })} className="w-full accent-gray-600" />
                    </div>
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">Spacing Y</label>
                      <input type="range" min="50" max="1000" step="10" value={watermarkSettings.gapY} onChange={(e) => setWatermarkSettings({ ...watermarkSettings, gapY: parseInt(e.target.value) })} className="w-full accent-gray-600" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'punch' && (
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <label className="text-sm font-medium text-gray-700">Enable Punching</label>
                <div className="relative inline-block w-10 mr-2 align-middle select-none transition duration-200 ease-in">
                  <input type="checkbox" name="toggle" id="toggle" className="toggle-checkbox absolute block w-5 h-5 rounded-full bg-white border-4 appearance-none cursor-pointer transition-transform duration-200 ease-in-out checked:translate-x-5 checked:border-blue-600" checked={punchSettings.enabled} onChange={(e) => setPunchSettings({ ...punchSettings, enabled: e.target.checked })} />
                  <label htmlFor="toggle" className="toggle-label block overflow-hidden h-5 rounded-full bg-gray-300 cursor-pointer"></label>
                </div>
              </div>

              <div className={`space-y-4 ${!punchSettings.enabled ? 'opacity-50 pointer-events-none' : ''}`}>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Start Number</label>
                  <input
                    type="number"
                    value={punchSettings.startNumber}
                    onChange={(e) => setPunchSettings({ ...punchSettings, startNumber: parseInt(e.target.value) })}
                    className="w-full p-2 border border-gray-300 rounded text-sm focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">X Offset</label>
                    <input type="number" value={punchSettings.xPos} onChange={(e) => setPunchSettings({ ...punchSettings, xPos: parseInt(e.target.value) })} className="w-full p-2 border border-gray-300 rounded text-sm focus:ring-blue-500 focus:border-blue-500" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Y Offset</label>
                    <input type="number" value={punchSettings.yPos} onChange={(e) => setPunchSettings({ ...punchSettings, yPos: parseInt(e.target.value) })} className="w-full p-2 border border-gray-300 rounded text-sm focus:ring-blue-500 focus:border-blue-500" />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Align X</label>
                    <select value={punchSettings.align} onChange={(e) => setPunchSettings({ ...punchSettings, align: e.target.value as any })} className="w-full p-2 border border-gray-300 rounded text-sm bg-white focus:ring-blue-500 focus:border-blue-500">
                      <option value="left">Left</option>
                      <option value="center">Center</option>
                      <option value="right">Right</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Align Y</label>
                    <select value={punchSettings.baseline} onChange={(e) => setPunchSettings({ ...punchSettings, baseline: e.target.value as any })} className="w-full p-2 border border-gray-300 rounded text-sm bg-white focus:ring-blue-500 focus:border-blue-500">
                      <option value="top">Top</option>
                      <option value="middle">Middle</option>
                      <option value="bottom">Bottom</option>
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Font Size</label>
                    <input type="number" value={punchSettings.fontSize} onChange={(e) => setPunchSettings({ ...punchSettings, fontSize: parseInt(e.target.value) })} className="w-full p-2 border border-gray-300 rounded text-sm focus:ring-blue-500 focus:border-blue-500" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Color</label>
                    <div className="flex h-[38px]">
                      <input type="color" value={punchSettings.color} onChange={(e) => setPunchSettings({ ...punchSettings, color: e.target.value })} className="w-10 h-full border border-gray-300 rounded-l p-0 cursor-pointer" />
                      <input type="text" value={punchSettings.color} onChange={(e) => setPunchSettings({ ...punchSettings, color: e.target.value })} className="flex-1 w-full p-2 border border-gray-300 border-l-0 rounded-r text-sm focus:ring-blue-500 focus:border-blue-500" />
                    </div>
                  </div>
                </div>

                <div className="pt-4 mt-2 border-t border-gray-100 space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Font File URL <span className="text-gray-400 font-normal">(.ttf/.otf, served from /public)</span>
                    </label>
                    <input
                      type="text"
                      value={punchSettings.fontUrl}
                      onChange={(e) => setPunchSettings({ ...punchSettings, fontUrl: e.target.value })}
                      placeholder="/fonts/Inter-Bold.ttf"
                      className="w-full p-2 border border-gray-300 rounded text-sm focus:ring-blue-500 focus:border-blue-500"
                    />
                    <p className="text-xs text-gray-400 mt-1">
                      Required for Merge Paths — text-anchor styling can&apos;t be boolean-merged, only real glyph outlines can.
                    </p>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Merge Mode</label>
                    <select
                      value={punchSettings.mergeMode}
                      onChange={(e) => setPunchSettings({ ...punchSettings, mergeMode: e.target.value as any })}
                      className="w-full p-2 border border-gray-300 rounded text-sm bg-white focus:ring-blue-500 focus:border-blue-500"
                    >
                      <option value="punch">Punch (cut number out as a hole)</option>
                      <option value="weld">Weld (union number as solid)</option>
                      <option value="intersect">Intersect (keep only overlap)</option>
                    </select>
                  </div>

                  <button
                    onClick={handleMergePaths}
                    disabled={layers.length === 0 || isMerging}
                    className="w-full py-2.5 bg-purple-600 text-white rounded-lg font-medium hover:bg-purple-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-sm"
                  >
                    {isMerging ? 'Merging…' : 'Merge Paths (Weld Number Into Layer)'}
                  </button>
                  {mergedLayerIds.size > 0 && (
                    <p className="text-xs text-green-600">
                      {mergedLayerIds.size} of {layers.length} layer(s) merged into a single combined path.
                    </p>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="p-4 bg-white border-t border-gray-200 flex flex-col gap-2">
          <button
            onClick={handleExportShowcase}
            disabled={layers.length === 0}
            className="w-full py-2 text-sm bg-gray-900 text-white rounded-lg font-medium hover:bg-gray-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-sm"
          >
            <Download className="w-4 h-4 mr-2" />
            Export Showcase (PNG)
          </button>

          <button
            onClick={handleDownloadPunchedSvgs}
            disabled={layers.length === 0}
            className="w-full py-2 text-sm bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-sm"
          >
            <FileDown className="w-4 h-4 mr-2" />
            Download Layers (ZIP)
          </button>

          <button
            onClick={handleExportCombinedSvg}
            disabled={layers.length === 0}
            className="w-full py-2 text-sm bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-sm"
          >
            <FileDown className="w-4 h-4 mr-2" />
            Export Combined (SVG)
          </button>
        </div>
      </div>

      {/* Main Preview Area */}
      <div
        ref={previewContainerRef}
        className="flex-1 relative overflow-hidden bg-gray-200"
      >
        {layers.length > 0 ? (() => {
          const baseW = layers[0]?.width || 800;
          const baseH = layers[0]?.height || 800;
          const layout = getLayerOffsets(layers.length, showcaseSettings.preset, showcaseSettings.spacingX, showcaseSettings.spacingY, baseW, baseH, showcaseSettings.scale);

          return (
            <div className="absolute inset-0 flex items-center justify-center">
              <div
                ref={showcaseRef}
                className="relative shadow-2xl flex-shrink-0 origin-center transition-transform duration-200"
                style={{
                  width: showcaseSettings.canvasWidth,
                  height: showcaseSettings.canvasHeight,
                  backgroundColor: showcaseSettings.backgroundColor,
                  transform: `scale(${previewScale})`,
                  overflow: 'hidden'
                }}
              >
                <div
                  className="absolute"
                  style={{
                    left: '50%',
                    top: '50%',
                    transform: `translate(calc(-50% - ${layout.minX}px), calc(-50% - ${layout.minY}px))`,
                    width: layout.totalWidth + (layers[0]?.width || 800) * showcaseSettings.scale,
                    height: layout.totalHeight + (layers[0]?.height || 800) * showcaseSettings.scale,
                  }}
                >
                  {layers.map((layer, idx) => {
                    let x = layout.offsets[idx].x;
                    let y = layout.offsets[idx].y;

                    // Generate preview content
                    let displayContent = layer.content;
                    const alreadyMerged = mergedLayerIds.has(layer.id);
                    if (punchSettings.enabled && !alreadyMerged) {
                      displayContent = punchNumberToSvg(layer.content, punchSettings.startNumber + idx);
                    }
                    const coloredContent = processSvgContent(displayContent, layer.color);

                    const drawW = (layer.width || 800) * showcaseSettings.scale;
                    const drawH = (layer.height || 800) * showcaseSettings.scale;

                    return (
                      <div
                        key={layer.id}
                        className="absolute top-0 left-0 transition-all duration-300 ease-out"
                        style={{
                          transform: `translate(${x}px, ${y}px)`,
                          width: drawW,
                          height: drawH,
                          filter: `drop-shadow(${showcaseSettings.dropShadowOffsetX}px ${showcaseSettings.dropShadowOffsetY}px ${showcaseSettings.dropShadowBlur}px rgba(0,0,0,${showcaseSettings.dropShadowOpacity}))`,
                          zIndex: idx,
                          opacity: layer.opacity,
                        }}
                      >
                        <div
                          dangerouslySetInnerHTML={{ __html: coloredContent }}
                          className="w-full h-full [&>svg]:w-full [&>svg]:h-full"
                        />
                      </div>
                    )
                  })}
                </div>

                {headerSettings.enabled && headerSettings.text && (
                  <div
                    className="absolute w-full text-center pointer-events-none z-50"
                    style={{
                      top: headerSettings.yPos,
                      color: headerSettings.color,
                      fontSize: headerSettings.size,
                      fontWeight: 'bold',
                      fontFamily: 'Arial, sans-serif'
                    }}
                  >
                    {headerSettings.text}
                  </div>
                )}

                {watermarkSettings.enabled && watermarkSettings.text && (
                  <div className="absolute inset-0 pointer-events-none z-50 overflow-hidden">
                    <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
                      <pattern
                        id="watermark-pattern"
                        width={watermarkSettings.gapX}
                        height={watermarkSettings.gapY}
                        patternUnits="userSpaceOnUse"
                        patternTransform={`rotate(${watermarkSettings.angle})`}
                      >
                        <text
                          x={watermarkSettings.gapX / 2}
                          y={watermarkSettings.gapY / 2}
                          dominantBaseline="middle"
                          textAnchor="middle"
                          fill={watermarkSettings.color}
                          opacity={watermarkSettings.opacity}
                          fontSize={watermarkSettings.size}
                          fontWeight="bold"
                          fontFamily="Arial, sans-serif"
                        >
                          {watermarkSettings.text}
                        </text>
                      </pattern>
                      <rect width="100%" height="100%" fill="url(#watermark-pattern)" />
                    </svg>
                  </div>
                )}
              </div>
            </div>
          );
        })() : (
          <div className="text-gray-400 flex flex-col items-center">
            <ImageIcon className="w-16 h-16 mb-4 opacity-50" />
            <p className="text-lg font-medium text-gray-500">Preview Area</p>
            <p className="text-sm">Upload layers to see them stacked here</p>
          </div>
        )}
      </div>

      <style dangerouslySetInnerHTML={{
        __html: `
        .custom-scrollbar::-webkit-scrollbar {
          width: 6px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: transparent;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background-color: #E5E7EB;
          border-radius: 10px;
        }
        .toggle-checkbox:checked {
          right: 0;
          border-color: #2563EB;
        }
        .toggle-checkbox:checked + .toggle-label {
          background-color: #2563EB;
        }
        .toggle-checkbox {
          right: 0;
          z-index: 1;
          border-color: #e5e7eb;
          transition: transform 0.2s ease-in-out;
        }
      `}} />
    </div>
  );
}