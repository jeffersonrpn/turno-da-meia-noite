# Caminhos e nomes
# ===============================
PICO8_DIR = /home/jeff/pico-8
PICO8 = $(PICO8_DIR)/pico8
GAME = midnightshift
SRC = $(GAME).p8
PNG_SRC = $(GAME).p8.png

HTML = index.html
JS = index.js

ITCH_USER = jeffersonrpn
ITCH_GAME = turno-da-meia-noite
ITCH_CHANNEL = html5

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
	@echo "Gerando cartucho..."
	$(PICO8) -export $(PNG) $(SRC)

	@echo "Gerando HTML..."
	$(PICO8) -export $(HTML) $(SRC)

	@echo "✔ Build concluído."

# Limpa exportações antigas
clean:
	@echo "Limpando arquivos gerados..."
	rm -f $(PNG)
	rm -f $(HTML)
	rm -f $(JS)

publish: build
	@echo "Publicando no itch.io..."
	butler push . $(ITCH_USER)/$(ITCH_GAME):$(ITCH_CHANNEL)