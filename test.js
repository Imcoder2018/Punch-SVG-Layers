const jsdom = require('jsdom');
const { JSDOM } = jsdom;
const dom = new JSDOM('');
const parser = new dom.window.DOMParser();

const content = `<svg><path id="layer_1_d32f2f" fill="#d32f2f" d="M9976,767c-18,90"/></svg>`;
const doc = parser.parseFromString(content, 'image/svg+xml');
const child = doc.documentElement.children[0];

const extractColorFromName = (name) => {
  const match = name.match(/(?:_|-)([a-fA-F0-9]{6})(?:_|-|\.svg|$)/i);
  return match ? `#${match[1].toUpperCase()}` : null;
};
console.log('ID:', child.getAttribute('id'));
console.log('FromName:', extractColorFromName(child.getAttribute('id')));

const getSvgColor = (node) => {
  const fill = node.getAttribute('fill');
  if (/^#(?:[0-9a-fA-F]{3}){1,2}$/.test(fill)) return fill.toUpperCase();
  return null;
};
console.log('FromSVG:', getSvgColor(child));
