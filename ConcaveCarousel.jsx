import { useRef, useState } from 'react';
import './ConcaveCarousel.css';

export default function ConcaveCarousel({ items }) {
  const [active, setActive] = useState(1);
  const start = useRef(null);
  const dragged = useRef(false);
  const move = (step) => setActive(value => (value + step + items.length) % items.length);
  const offset = (index) => {
    let value = index - active;
    if (value > items.length / 2) value -= items.length;
    if (value < -items.length / 2) value += items.length;
    return value;
  };
  return (
    <section className="concave-carousel" aria-roledescription="carrossel" aria-label="Fotos dos produtos Sunshine"
      onKeyDown={event => {
        if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') {
          event.preventDefault();
          move(event.key === 'ArrowRight' ? 1 : -1);
        }
      }}>
      <div className="concave-carousel__stage"
        onPointerDown={event => {
          if (event.pointerType === 'mouse' && event.button !== 0) return;
          dragged.current = false;
          start.current = { x: event.clientX, y: event.clientY };
          event.currentTarget.setPointerCapture(event.pointerId);
        }}
        onPointerCancel={() => { start.current = null; }}
        onPointerUp={event => {
          if (!start.current) return;
          const dx = event.clientX - start.current.x;
          const dy = event.clientY - start.current.y;
          start.current = null;
          if (Math.abs(dx) > 40 && Math.abs(dx) > Math.abs(dy)) {
            dragged.current = true;
            move(dx < 0 ? 1 : -1);
          } else {
            const card = document.elementFromPoint(event.clientX, event.clientY)?.closest('[data-carousel-index]');
            if (card && event.currentTarget.contains(card)) setActive(Number(card.dataset.carouselIndex));
          }
        }}>
        {items.map((item, index) => {
          const position = offset(index);
          return <button key={item.src} type="button" className="concave-carousel__card"
            style={{ '--position': position, '--depth': Math.abs(position), zIndex: 3 - Math.abs(position) }}
            aria-label={`Mostrar ${item.alt}`} aria-pressed={index === active}
            data-carousel-index={index}
            onClick={() => { if (!dragged.current) setActive(index); dragged.current = false; }}>
            <img src={item.src} alt={item.alt} width={item.width} height={item.height} draggable="false" />
          </button>;
        })}
      </div>
      <div className="concave-carousel__controls">
        <button type="button" onClick={() => move(-1)} aria-label="Produto anterior">←</button>
        <p aria-live="polite" aria-atomic="true"><span>{String(active + 1).padStart(2, '0')}</span> / {String(items.length).padStart(2, '0')}</p>
        <button type="button" onClick={() => move(1)} aria-label="Próximo produto">→</button>
      </div>
      <p className="concave-carousel__caption">{items[active].alt}</p>
    </section>
  );
}
