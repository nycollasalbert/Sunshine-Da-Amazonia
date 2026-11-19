import { createRoot } from 'react-dom/client';
import ConcaveCarousel from './ConcaveCarousel';

const mount = document.getElementById('product-carousel-root');
if (mount) {
  const items = Array.from(mount.querySelectorAll('img'), image => ({
    src: image.getAttribute('src'), alt: image.alt,
    width: image.getAttribute('width'), height: image.getAttribute('height')
  }));
  if (items.length > 1) createRoot(mount).render(<ConcaveCarousel items={items} />);
}
