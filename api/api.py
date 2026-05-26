import os
import sys
from flask import Flask, request, jsonify
from llama_index.core import SimpleDirectoryReader, Settings, VectorStoreIndex, StorageContext, load_index_from_storage
from llama_index.embeddings.ollama import OllamaEmbedding
from llama_index.llms.ollama import Ollama

app = Flask(__name__)

# Configurações Globais
Settings.embed_model = OllamaEmbedding(model_name="nomic-embed-text")
Settings.chunk_size = 256 
Settings.chunk_overlap = 25 
Settings.llm = Ollama(
    model="qwen2.5:0.5b", 
    request_timeout=600.0, 
    temperature=0.0,
    additional_kwargs={"num_ctx": 2048} 
)

motor_de_busca = None
indice = None

def inicializar_cerebro():
    global motor_de_busca, indice

    diretorio_wiki = "dados"
    if len(sys.argv) > 2 and sys.argv[1] == "--wiki-dir":
        diretorio_wiki = sys.argv[2]

    print(f"🧠 Lendo arquivos da wiki em: {diretorio_wiki}")
    os.makedirs(diretorio_wiki, exist_ok=True)

    persist_dir = os.path.join(diretorio_wiki, ".cerebro_index")

    # OTIMIZAÇÃO: Verifica se o índice já existe no disco
    if os.path.exists(persist_dir):
        print("📦 Carregando índice do disco (Inicialização rápida)...")
        storage_context = StorageContext.from_defaults(persist_dir=persist_dir)
        indice = load_index_from_storage(storage_context)
    else:
        print("⚙️ Criando índice vetorial pela primeira vez (Isso pode demorar)...")
        leitor = SimpleDirectoryReader(input_dir=diretorio_wiki, required_exts=[".md"], recursive=True)
        documentos = leitor.load_data()
        indice = VectorStoreIndex.from_documents(documentos)
        
        # Salva o índice no disco para as próximas execuções
        indice.storage_context.persist(persist_dir=persist_dir)
        print("💾 Índice salvo no disco com sucesso!")

    # Otimiza a consulta para trazer as 2 melhores fatias de contexto
    motor_de_busca = indice.as_query_engine(similarity_top_k=2)
    print("✅ Segundo Cérebro pronto e escutando na porta 5000!")

@app.route('/perguntar', methods=['POST'])
def perguntar():
    dados = request.get_json()
    if not dados or 'pergunta' not in dados:
        return jsonify({"erro": "Pergunta ausente."}), 400
    
    pergunta_usuario = dados['pergunta']
    contexto_arquivo = dados.get('contexto', '')

    prompt_final = pergunta_usuario
    if contexto_arquivo:
        prompt_final = f"Contexto do arquivo:\n{contexto_arquivo}\n\nPergunta: {pergunta_usuario}"

    try:
        resposta = motor_de_busca.query(prompt_final)
        return jsonify({"resposta": str(resposta)})
    except Exception as e:
        return jsonify({"erro": str(e)}), 500

if __name__ == "__main__":
    inicializar_cerebro()
    app.run(host='127.0.0.1', port=5000)
