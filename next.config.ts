import type {NextConfig} from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: false,
  },
  // Allow access to remote image placeholder.
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'picsum.photos',
        port: '',
        pathname: '/**', // This allows any path under the hostname
      },
    ],
  },
  output: 'standalone',
  transpilePackages: ['motion'],
  webpack: (config, {dev}) => {
    // HMR is disabled in AI Studio via DISABLE_HMR env var.
    // Do not modifyâfile watching is disabled to prevent flickering during agent edits.
    if (dev && process.env.DISABLE_HMR === 'true') {
      config.watchOptions = {
        ignored: /.*/,
      };
    }
    
    // Add externals or alias to ignore jsdom inside paper.js when building
    if (!config.resolve.alias) {
      config.resolve.alias = {};
    }
    // Force paper to resolve to the browser/core build without node dependencies
    config.resolve.alias['paper$'] = 'paper/dist/paper-core.js';
    
    // Stub out the node-canvas and jsdom dependencies inside paper.js
    if (!config.resolve.fallback) {
      config.resolve.fallback = {};
    }
    config.resolve.fallback['jsdom'] = false;
    config.resolve.fallback['canvas'] = false;
    
    return config;
  },
};

export default nextConfig;
