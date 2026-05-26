local M = {}

-- Dependências do nui.vim
local Input = require("nui.input")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

M.api_job_id = nil
M.config = {
	api_url = "http://127.0.0.1:5000/perguntar",
	python_cmd = vim.fn.stdpath("data") .. "/lazy/vim-cerebro/api/.venv/bin/python",
	wiki_dir = vim.fn.expand("~/minhas_anotacoes"),
	api_dir = vim.fn.expand("<sfile>:p:h:h") .. "/api", -- Ajuste conforme o path de instalação
}

-- Inicializa o Servidor Flask em Background
function M.start_server()
	local check_cmd = "curl -s -o /dev/null " .. M.config.api_url .. ' || echo "offline"'
	local status = vim.fn.system(check_cmd)

	if status:match("offline") then
		vim.notify("🧠 Inicializando o Segundo Cérebro em background...", vim.log.levels.INFO)
		local cmd = { M.config.python_cmd, M.config.api_dir .. "/api.py", "--wiki-dir", M.config.wiki_dir }

		M.api_job_id = vim.fn.jobstart(cmd, { cwd = M.config.api_dir })
	end
end

-- Desliga o Servidor
function M.stop_server()
	if M.api_job_id then
		vim.notify("🧠 Desligando o Segundo Cérebro e liberando a RAM...", vim.log.levels.INFO)
		vim.fn.jobstop(M.api_job_id)
	end
end

-- Função auxiliar para exibir a resposta em um Popup
local function show_response_popup(title, content)
	local popup = Popup({
		enter = true,
		focusable = true,
		border = {
			style = "rounded",
			text = { top = " " .. title .. " ", top_align = "center" },
		},
		position = "50%",
		size = { width = "70%", height = "60%" },
		buf_options = { modifiable = true, readonly = false, filetype = "markdown" },
	})

	popup:mount()

	-- Fecha o popup com 'q' ou <Esc>
	popup:map("n", "q", function()
		popup:unmount()
	end, { noremap = true })
	popup:map("n", "<Esc>", function()
		popup:unmount()
	end, { noremap = true })

	-- Insere o texto
	local lines = vim.split(content, "\n")
	vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(popup.bufnr, "modifiable", false)
end

-- Função principal de requisição
local function send_query(pergunta, usar_contexto)
	local contexto = ""
	if usar_contexto then
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		contexto = table.concat(lines, "\n")
	end

	vim.notify("⏳ Consultando a base...", vim.log.levels.INFO)

	local payload = vim.fn.json_encode({ pergunta = pergunta, contexto = contexto })
	local temp_file = vim.fn.tempname()

	local cmd = {
		"curl",
		"-s",
		"-X",
		"POST",
		M.config.api_url,
		"-H",
		"Content-Type: application/json",
		"-d",
		payload,
		"-o",
		temp_file,
	}

	vim.fn.jobstart(cmd, {
		on_exit = function(_, exit_code)
			if exit_code == 0 and vim.fn.filereadable(temp_file) == 1 then
				local raw_json = table.concat(vim.fn.readfile(temp_file), "")
				vim.fn.delete(temp_file)

				local ok, response = pcall(vim.fn.json_decode, raw_json)
				if ok and response.resposta then
					vim.schedule(function()
						show_response_popup("🧠 Resposta do Cérebro", response.resposta)
					end)
				else
					vim.schedule(function()
						vim.notify("❌ Erro ao decodificar resposta da API.", vim.log.levels.ERROR)
					end)
				end
			end
		end,
	})
end

-- Cria o Input do Nui.vim
function M.ask(usar_contexto)
	local title = usar_contexto and " Pergunta sobre este arquivo " or " Pergunta para o Cérebro "

	local input = Input({
		position = "50%",
		size = { width = 50 },
		border = { style = "rounded", text = { top = title } },
	}, {
		prompt = "> ",
		default_value = "",
		on_submit = function(pergunta)
			if pergunta and pergunta ~= "" then
				send_query(pergunta, usar_contexto)
			end
		end,
	})

	input:mount()
end

return M
