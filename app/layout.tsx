import type {Metadata} from 'next';
import './globals.css'; // Global styles

export const metadata: Metadata = {
  title: 'My Google AI Studio App',
  description: 'My Google AI Studio App',
};

export default function RootLayout({children}: {children: React.ReactNode}) {
  return (
    <html lang="en">
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              const originalDefineProperty = Object.defineProperty;
              Object.defineProperty = function(obj, prop, descriptor) {
                if (obj === window && prop === 'fetch' && !descriptor.set) {
                  descriptor.set = function() {};
                  descriptor.configurable = true;
                }
                return originalDefineProperty(obj, prop, descriptor);
              };
            `,
          }}
        />
      </head>
      <body suppressHydrationWarning>{children}</body>
    </html>
  );
}
