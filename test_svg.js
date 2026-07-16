const fs = require('fs');
const jsdom = require('jsdom');
const { JSDOM } = jsdom;
const dom = new JSDOM('');
const parser = new dom.window.DOMParser();

const content = fs.readFileSync('C:\\Users\\PMYLS\\Downloads\\vectorized_step_5_median1_blur0.3_sat2.0_turd50_alpha0.00 (6).svg', 'utf8');
const doc = parser.parseFromString(content, 'image/svg+xml');
const svgElement = doc.documentElement;

const potentialLayers = Array.from(svgElement.children).filter(el => 
  !['defs', 'style', 'title', 'desc'].includes(el.tagName.toLowerCase())
);

console.log('potentialLayers length:', potentialLayers.length);

const extractColorFromName = (name) => {
  const match = name.match(/(?:_|-)([a-fA-F0-9]{6})(?:_|-|\.svg|$)/i);
  return match ? `#${match[1].toUpperCase()}` : null;
};

potentialLayers.forEach((child, index) => {
  const layerName = child.getAttribute('id') || `Layer ${index + 1}`;
  const nameColor = extractColorFromName(layerName);
  
  const getSvgColor = (node) => {
    const fill = node.getAttribute('fill');
    if (/^#(?:[0-9a-fA-F]{3}){1,2}$/.test(fill)) return fill.toUpperCase();
    return null;
  };
  
  console.log(`Layer ${index}: name=${layerName}, nameColor=${nameColor}, svgColor=${getSvgColor(child)}`);
});
