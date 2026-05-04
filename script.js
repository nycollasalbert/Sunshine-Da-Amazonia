document.documentElement.classList.add("js");

document.addEventListener("DOMContentLoaded", () => {
    const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    const debounce = (callback, delay = 160) => {
        let timeoutId;
        return (...args) => {
            window.clearTimeout(timeoutId);
            timeoutId = window.setTimeout(() => callback(...args), delay);
        };
    };

    const setupMenu = () => {
        const button = document.querySelector("[data-menu-toggle]");
        const menu = document.querySelector("[data-menu]");
        const icon = button?.querySelector("i");

        if (!button || !menu || !icon) return;

        const setMenuState = (isOpen) => {
            button.setAttribute("aria-expanded", String(isOpen));
            button.setAttribute("aria-label", isOpen ? "Fechar menu" : "Abrir menu");
            menu.classList.toggle("is-open", isOpen);
            menu.toggleAttribute("inert", !isOpen);
            icon.classList.toggle("fa-bars", !isOpen);
            icon.classList.toggle("fa-xmark", isOpen);
        };

        button.addEventListener("click", () => {
            setMenuState(button.getAttribute("aria-expanded") !== "true");
        });

        menu.addEventListener("click", (event) => {
            if (event.target.closest("a")) setMenuState(false);
        });

        document.addEventListener("keydown", (event) => {
            if (event.key === "Escape" && button.getAttribute("aria-expanded") === "true") {
                setMenuState(false);
                button.focus();
            }
        });

        setMenuState(false);
    };

    const setupHeader = () => {
        const header = document.querySelector("[data-header]");
        if (!header) return;

        let ticking = false;
        const update = () => {
            header.classList.toggle("is-scrolled", window.scrollY > 48);
            ticking = false;
        };

        window.addEventListener(
            "scroll",
            () => {
                if (!ticking) {
                    ticking = true;
                    window.requestAnimationFrame(update);
                }
            },
            { passive: true }
        );

        update();
    };

    const setupFocusWords = () => {
        const container = document.querySelector("[data-focus-container]");
        const frame = document.querySelector("[data-focus-frame]");
        const words = [...document.querySelectorAll("[data-focus-word]")];

        if (!container || !frame || !words.length) return;

        let activeIndex = 0;
        let intervalId;

        const setActive = (index) => {
            activeIndex = index;

            words.forEach((word, wordIndex) => {
                const isActive = wordIndex === activeIndex;
                word.classList.toggle("is-active", isActive);
                word.setAttribute("aria-pressed", String(isActive));
            });

            const activeWord = words[activeIndex];
            const wordRect = activeWord.getBoundingClientRect();
            const containerRect = container.getBoundingClientRect();

            frame.style.width = `${wordRect.width}px`;
            frame.style.height = `${wordRect.height}px`;
            frame.style.transform = `translate(${wordRect.left - containerRect.left}px, ${wordRect.top - containerRect.top}px)`;
            frame.classList.add("is-visible");
        };

        const next = () => setActive((activeIndex + 1) % words.length);
        const stop = () => window.clearInterval(intervalId);
        const start = () => {
            if (!prefersReducedMotion) {
                stop();
                intervalId = window.setInterval(next, 2200);
            }
        };

        words.forEach((word, index) => {
            word.addEventListener("pointerenter", () => {
                stop();
                setActive(index);
            });
            word.addEventListener("focus", () => {
                stop();
                setActive(index);
            });
            word.addEventListener("pointerleave", start);
            word.addEventListener("blur", start);
            word.addEventListener("click", () => setActive(index));
        });

        window.addEventListener("resize", debounce(() => setActive(activeIndex)), { passive: true });

        const init = () => {
            setActive(0);
            start();
        };

        if (document.fonts?.ready) {
            document.fonts.ready.then(init).catch(init);
        } else {
            window.setTimeout(init, 120);
        }
    };

    const setupReveal = () => {
        const elements = [...document.querySelectorAll(".reveal")];
        if (!elements.length) return;

        if (prefersReducedMotion || !("IntersectionObserver" in window)) {
            elements.forEach((element) => element.classList.add("is-visible"));
            return;
        }

        const observer = new IntersectionObserver(
            (entries, revealObserver) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add("is-visible");
                        revealObserver.unobserve(entry.target);
                    }
                });
            },
            {
                threshold: 0.12,
                rootMargin: "0px 0px -50px 0px"
            }
        );

        elements.forEach((element) => observer.observe(element));
    };

    const setupMagneticButtons = () => {
        const buttons = [...document.querySelectorAll("[data-magnetic]")];
        const supportsFinePointer = window.matchMedia("(pointer: fine)").matches;

        if (!buttons.length || !supportsFinePointer || prefersReducedMotion) return;

        buttons.forEach((button) => {
            button.addEventListener("pointermove", (event) => {
                const rect = button.getBoundingClientRect();
                const x = event.clientX - rect.left - rect.width / 2;
                const y = event.clientY - rect.top - rect.height / 2;
                button.style.transform = `translate(${x * 0.18}px, ${y * 0.18}px) scale(1.02)`;
            });

            button.addEventListener("pointerleave", () => {
                button.style.transform = "";
            });
        });
    };

    const setupCounters = () => {
        const counters = [...document.querySelectorAll("[data-counter]")];
        if (!counters.length) return;

        const formatter = new Intl.NumberFormat("pt-BR");

        const animate = (counter) => {
            const target = Number(counter.dataset.target || 0);
            const prefix = counter.dataset.prefix || "";
            const suffix = counter.dataset.suffix || "";
            const duration = prefersReducedMotion ? 0 : 1800;
            const startTime = performance.now();

            const render = (value) => {
                counter.textContent = `${prefix}${formatter.format(Math.round(value))}${suffix}`;
            };

            if (!duration) {
                render(target);
                return;
            }

            const step = (now) => {
                const progress = Math.min((now - startTime) / duration, 1);
                const eased = 1 - Math.pow(1 - progress, 3);
                render(target * eased);

                if (progress < 1) {
                    window.requestAnimationFrame(step);
                }
            };

            window.requestAnimationFrame(step);
        };

        if (!("IntersectionObserver" in window)) {
            counters.forEach(animate);
            return;
        }

        const observer = new IntersectionObserver(
            (entries, counterObserver) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        animate(entry.target);
                        counterObserver.unobserve(entry.target);
                    }
                });
            },
            { threshold: 0.45 }
        );

        counters.forEach((counter) => observer.observe(counter));
    };

    const setupImageModal = () => {
        const modal = document.querySelector("[data-image-modal]");
        const modalImage = document.querySelector("[data-modal-image]");
        const closeButton = document.querySelector("[data-modal-close]");

        if (!modal || !modalImage || !closeButton) return;

        let previousFocus = null;

        const openModal = (trigger) => {
            const image = trigger.querySelector("img");
            const src = trigger.dataset.full || image?.currentSrc || image?.src;
            const alt = trigger.dataset.alt || image?.alt || "Imagem ampliada";

            if (!src) return;

            previousFocus = document.activeElement;
            modalImage.src = src;
            modalImage.alt = alt;
            modal.hidden = false;
            document.body.classList.add("is-modal-open");
            closeButton.focus();
        };

        const closeModal = () => {
            modal.hidden = true;
            modalImage.removeAttribute("src");
            document.body.classList.remove("is-modal-open");

            if (previousFocus instanceof HTMLElement) {
                previousFocus.focus();
            }
        };

        document.addEventListener("click", (event) => {
            const trigger = event.target.closest("[data-image-zoom]");
            if (trigger) openModal(trigger);
        });

        closeButton.addEventListener("click", closeModal);

        modal.addEventListener("click", (event) => {
            if (event.target === modal) closeModal();
        });

        document.addEventListener("keydown", (event) => {
            if (event.key === "Escape" && !modal.hidden) closeModal();
        });
    };

    setupMenu();
    setupHeader();
    setupFocusWords();
    setupReveal();
    setupMagneticButtons();
    setupCounters();
    setupImageModal();
});
