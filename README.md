# 🧠 vim-cerebro

Um plugin para Neovim que integra um Segundo Cérebro RAG (Retrieval-Augmented Generation) diretamente no seu editor usando **Ollama** e **LlamaIndex**.

Com o `cerebro.nvim`, você pode fazer perguntas sobre suas anotações em Markdown e interagir com modelos locais de Inteligência Artificial sem sair do código, mantendo tudo 100% privado e open-source.

## 🚀 Pré-requisitos

1. **Neovim** (0.8.0 ou superior).
2. **Python 3.8+**.
3. **[Ollama](https://ollama.com/)** instalado e rodando no seu sistema.
4. Modelos do Ollama baixados previamente. Por padrão, o plugin utiliza:
   ```bash
   ollama pull qwen2.5:0.5b
   ollama pull nomic-embed-text
   ```
   
## 📦 Instalação

Usando [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ymtec90/cerebro.nvim",
    dependencies = {
        "MunifTanjim/nui.vim", -- Necessário para a interface visual
    },
    build = "cd api && ./install.sh", -- Configura o ambiente virtual Python automaticamente
    config = function()
        local cerebro = require("cerebro")
        
        -- Configurações Opcionais (Descomente e ajuste se necessário)
        -- cerebro.config.wiki_dir = vim.fn.expand("~/minhas_anotacoes")
        -- cerebro.config.api_dir = vim.fn.stdpath("data") .. "/lazy/cerebro.nvim/api"

        -- Liga o servidor ao abrir e desliga ao fechar o Neovim
        vim.api.nvim_create_autocmd("VimEnter", { callback = cerebro.start_server })
        vim.api.nvim_create_autocmd("VimLeave", { callback = cerebro.stop_server })

        -- Mapeamentos
        vim.keymap.set("n", "<leader>ce", function() cerebro.ask(false) end, { desc = "Cérebro: Pergunta Simples" })
        vim.keymap.set("n", "<leader>ctx", function() cerebro.ask(true) end, { desc = "Cérebro: Pergunta com Contexto" })
    end
}
```

## ⌨️ Comandos e Atalhos

O plugin expõe os seguintes atalhos (mapeados para a tecla `<leader>`):

* `<leader>ce`: Abre um prompt para uma pergunta simples para a IA.

* `<leader>ctx`: Envia a pergunta junto com todo o contexto do arquivo atual que você está editando.

Comandos manuais disponíveis:

* `:Cerebro [pergunta]`
* `:CerebroContexto [pergunta]`
* `:CerebroModelo [nome-do-modelo] (ex: :CerebroModelo llama3)`

## 🛠️ Estrutura do Projeto
* `lua/cerebro/init.lua`: O coração do frontend no Neovim. Gerencia a interface gráfica (via nui.vim) e orquestra os processos do sistema (jobs).

* `api/api.py`: O backend em Flask. Ele indexa seus arquivos .md e cuida da comunicação com a API local do Ollama usando LlamaIndex.

## 📝 Licença
Distribuído sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.
