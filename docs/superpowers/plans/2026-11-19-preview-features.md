# Melhorias da prévia no oficial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transferir melhorias aprovadas sem alterar banners oficiais.
**Architecture:** Entrada React exclusiva para o carrossel existente, CSS aditivo restrito e alterações pontuais de HTML. Não copiar folhas globais da prévia.
**Tech Stack:** HTML, CSS, JavaScript, React e esbuild já usados na prévia.
**Spec:** C:\Users\nyco\Documents\meu estudo\Sunshine-Da-Amazonia\docs\superpowers\specs\2026-11-19-preview-features-design.md

## Task 1: Baseline e proteção
- [ ] Conferir .gitignore e rastreamento de segredos antes de commit; criar tag de recuperação específica.
- [ ] Excluir docs e segredos do deploy.
- [ ] Criar testes node:assert que inicialmente falham para açaí, categoria removida e carrossel, e que preservam hero, três artigos launch-banner e hashes dos banners conforme baseline.

## Task 2: Transferência mínima
**Files:** index.html, product-carousel.jsx, ConcaveCarousel.jsx, ConcaveCarousel.css, product-enhancements.css, package.json/package-lock.json e assets novos.
**Interface:** product-carousel.jsx monta ConcaveCarousel({items}) apenas em #product-carousel-root, lendo suas três imagens; bundle exclusivo product-carousel.bundle.js/css.
- [ ] Copiar componente e imagens transparentes da prévia; copiar imagem açaí e inserir o botão de zoom na galeria.
- [ ] Remover seção exclusive-blends-title, adicionar tag Açaí e aplicar diferenças textuais fora dos banners conforme design aprovado.
- [ ] Inserir carrossel depois dos banners e antes das categorias sem alterar artigos existentes.
- [ ] Extrair apenas regras de botões glossy e products-footer; escopar layout do carrossel a seu contêiner.
- [ ] Configurar build com versões exatas já usadas na prévia; executar build e testes.

## Task 3: Navegador e publicação
- [ ] Testar em 320/390/1440, imagens, zoom, menu e carrossel por botões e teclado, sem overflow e pageerror.
- [ ] Revisar diff e testes de preservação; commit.
- [ ] Publicar projeto sunshine-da-amazonia; verificar domínio oficial e registrar deployment.

## Review Focus
Banners e hero inalterados salvo acabamento dos botões; CSS não modifica cabeçalho; referências de imagens existem; carrossel acessível com movimento reduzido; nenhuma prévia é publicada ou alterada.
