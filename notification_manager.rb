require 'net/http'
require 'uri'
require 'json'

require_relative 'models/alert_context'
require_relative 'models/alert_strategies/discord'

class NotificaionManager
  NOTIFIERS = [
    {
      platform: 'Discord',
      log_file_path: '/home/arthur/Desktop/list/log/development.log',
      uri: ENV['DISCORD_WEBHOOK_URL']
    }
  ]

  KEYWORDS = [
    /ERROR/i,                                   # Captura logs padrão de erro do Rails e de Gems
    /FATAL/i,                                   # Erros críticos que geralmente interrompem a aplicação
    /ActiveRecord::StatementInvalid/i,          # Erros de SQL (Sintaxe incorreta, violação de Constraints)
    /ActiveRecord::ConnectionNotEstablished/i,  # Aplicação não consegue falar com o Banco de Dados
    /ActiveRecord::ConnectionTimeoutError/i,    # O Banco demorou demais para responder à conexão
    /Internal Server Error/i,                   # Erro 500 genérico renderizado para o usuário
    /ActiveRecord::RecordNotUnique/i,           # Tentativa de duplicar um registro único (Ex: mesmo e-mail)
    /PG::Error/i,                               # Erros específicos do driver do PostgreSQL
    /Mysql2::Error/i,                           # Erros específicos do driver do MySQL
    /NoMethodError/i,                           # Bug clássico: tentou chamar algo em um objeto que é 'nil'
    /ROLLBACK/i,                                # Indica que uma operação no banco foi cancelada por falha
    /Mongoid::Errors::Validations/i,            # Falha de validação quando se usa o método '!' (ex: save!)
    /Mongoid::Errors::DocumentNotFound/i,       # Tentativa de buscar um documento que não existe (id inválido)
    /Mongo::Error::NoServerAvailable/i,         # O servidor MongoDB está fora do ar ou inacessível
    /Mongo::Error::SocketError/i,               # Problemas de rede/conexão com o cluster do MongoDB
    /Mongo::Error::OperationFailure/i           # Erro em operações específicas (ex: falha de autenticação ou índice)
  ]


  def initialize; end

  def self.call
    new.call
  end

  def call
    run
  end

  private

  def run
    NOTIFIERS.each do |notifier|
      watch(notifier)
    end
  end

  def watch(notifier)
    platform = Object.const_get("AlertStrategies::#{notifier[:platform]}")
    log_file_path = notifier[:log_file_path]
    uri =  notifier[:uri]

    # TODO check log_file_path
    alert = AlertContext.new(platform:, log_file_path:, uri:)

    puts "iniciando monitoramento..."

    begin
      file = load_log_file_from_the_very_end(log_file_path: log_file_path)

      loop do
        line = file.gets

        if line
          alert.notify(message: line) if NotificaionManager::KEYWORDS.any? { |keyword| line =~ keyword}
        else
        
          if File.size(log_file_path) < file.pos
            file.close
            file.open(log_file_path, 'r')
          end
          sleep 1
        end
      end
    rescue => exception
      puts exception.message
    ensure
      file&.close
    end
  end

  def load_log_file_from_the_very_end(log_file_path: nil)
    file = File.open(log_file_path, 'r')
    file.seek(0, IO::SEEK_END)
    file
  end
end

NotificaionManager.()
