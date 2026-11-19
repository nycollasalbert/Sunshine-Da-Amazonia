# Melhorias da prévia no site oficial

## Escopo aprovado
Trazer imagens atualizadas, carrossel de três frascos na seção produtos e acabamento de vidro somente nos botões. Preservar banners oficiais, cabeçalho, fundos, textos e posição dos banners. Não importar preview.css nem glossy.css integralmente.

## Complemento solicitado
Transferir mudanças textuais verificadas fora dos banners: adicionar Açaí em Óleos Naturais, remover categoria Blends Exclusivos e seus seis itens, retirar a frase de isenção RDC ausente na prévia e ampliar products-footer para clamp(1.15rem, 2vw, 1.45rem), peso 700 e entrelinha 1.65. Preservar o restante dos dados legais. A galeria da prévia difere somente pela adição da foto de açaí; Buriti e Formiga já existem no oficial.

## Implementação proposta
Reutilizar ConcaveCarousel.jsx e CSS da prévia com entrada exclusiva, sem efeitos de scroll nem alterações do hero. Usar dependências React e esbuild nas versões já usadas na prévia. Adicionar folha CSS restrita aos botões, carrossel e products-footer. Manter fontes e dimensões dos banners existentes. Carrossel depois dos banners e antes das categorias, com três imagens transparentes da prévia.

## Validação e segurança
Salvar ponto Git anterior sem incluir .env.local; impedir publicação de docs, Git e segredos. Testes comparam banners e hero ao baseline e hashes das imagens de banners; verificam textos, assets e CSS restrito. Build e navegador em 320/390/1440, navegação de carrossel por botões/teclado, zoom açaí, menu, ausência de overflow e erros. Publicar somente oficial e verificar domínio.
