# Caminhos e nomes
# ===============================
PICO8_DIR = /home/jeff/pico-8
PICO8 = $(PICO8_DIR)/pico8
GAME = midnightshift
SRC = $(GAME).p8
PNG_SRC = $(GAME).p8.png
EXPORT_DIR = export
HTML_EXPORT = $(EXPORT_DIR)/$(GAME).html
JS_EXPORT = $(EXPORT_DIR)/$(GAME).js
PICO8_CARTS = /home/jeff/.lexaloffle/pico-8/carts
REPO_DIR = /home/jeff/workspace/ultimoturno
SRC_PATH = $(REPO_DIR)/$(SRC)

# Comandos principais
# ===============================

# Abre o jogo no PICO-8
run:
	@echo "Rodando o jogo no PICO-8..."
	$(PICO8) -run $(SRC_PATH) -windowed 1

# Salva o projeto atual (garante que o .p8 esteja no local certo)
save:
	@echo "Salvando jogo..."
	$(PICO8) -x "SAVE @$(SRC_PATH)" -x "QUIT"

# Copia o cart do diretório padrão do PICO-8 para o repositório
copy:
	@echo "Copiando $(SRC) do PICO-8 para o repositório..."
	cp $(PICO8_CARTS)/$(SRC) $(REPO_DIR)/
	cp $(PICO8_CARTS)/$(PNG_SRC) $(REPO_DIR)/
	@echo "Arquivo copiado para $(REPO_DIR)/$(SRC)"
reversecopy:
	@echo "Copiando $(SRC) do repositório para o PICO-8..."
	cp $(REPO_DIR)/$(SRC) $(PICO8_CARTS)/
	@echo "Arquivo copiado para $(PICO8_CARTS)/$(SRC)"

# Exporta para web (HTML + JS)
build:
	@echo "Exportando versão web..."
	mkdir -p $(EXPORT_DIR)
	$(PICO8) -export $(HTML_EXPORT) $(PNG_SRC)
	@echo "Arquivos exportados em $(EXPORT_DIR)/"

# Exporta e publica no GitHub Pages
NOW = $(shell date +%Y-%m-%d_%H-%M-%S)
deploy:
	@echo "Publicando no GitHub Pages $(NOW)..."
	git checkout -B gh-pages
	cp -r $(EXPORT_DIR)/* .
	git add $(HTML_EXPORT) $(JS_EXPORT)
	git commit -m "Publicando jogo em $(NOW)"
	git push -f origin gh-pages
	git checkout main
	@echo "✨ Jogo publicado em: https://$(shell git config user.name).github.io/$(GAME)/"

# Limpa exportações antigas
clean:
	@echo "Limpando exportações..."
	rm -rf $(EXPORT_DIR)
	rm -f index.html index.js index.data
