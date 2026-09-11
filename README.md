# Codex Limite para Apple Silicon

Indicador local de limite do Codex para a barra de menus do macOS. Ele mostra o limite semanal ou a janela de 5 horas, conforme a opção escolhida no menu, e acompanha automaticamente a execução do aplicativo Codex/ChatGPT.

Este projeto é um recurso comunitário/local e não é um produto oficial da OpenAI.

Criado por Abel Angelo.

## Compatibilidade

- Mac Apple Silicon (arm64) somente.
- macOS compatível com a versão instalada do ChatGPT/Codex e com as Xcode Command Line Tools.
- Aplicativo ChatGPT/Codex instalado e autenticado localmente.
- Xcode Command Line Tools, para disponibilizar xcrun swiftc.

O projeto não inclui uma versão Intel. O instalador verifica o hardware e o build usa o alvo arm64 padrão do Mac atual.

## Instalação

Abra o Terminal na pasta do projeto e execute:

    ./Scripts/install.sh

O instalador:

1. compila o aplicativo para Apple Silicon;
2. instala o app em ~/Applications/Codex Limite.app;
3. instala o supervisor em ~/Library/Application Support/CodexWeeklyLimit;
4. cria o LaunchAgent com os caminhos do usuário atual;
5. inicia o supervisor.

O indicador real só é executado enquanto o processo principal do Codex estiver ativo. O supervisor permanece invisível para acompanhar abertura, encerramento e reinício do Codex. Fechar o Codex encerra o indicador; abrir o Codex novamente inicia uma nova instância.

## Idioma

O menu usa inglês por padrão. Quando o primeiro idioma preferido do macOS/Codex for `pt-BR`, o menu será exibido em português do Brasil. Outros idiomas usam inglês como fallback. A mudança de idioma passa a valer ao reiniciar o Codex e o indicador.

Contas sem janela de 5 horas continuam vendo o cartão informativo, marcado como não incluído no plano. Os controles de exibição e alternância dessa janela ficam ocultos, e a barra volta ao limite semanal sem apagar as preferências salvas. Se uma atualização falhar, o indicador preserva o último estado conhecido e mostra o aviso de dado desatualizado.

## Exibição

Por padrão, a barra mostra o limite semanal. No menu do indicador, use:

    Exibir limite de 5 horas na barra

Quando ativada, a barra mostra somente o limite de 5 horas. O menu aberto continua exibindo os dois limites.

Também estão disponíveis:

As três opções aparecem como switches personalizados com visual alinhado ao macOS e semântica acessível. Um switch ativo fica verde e um switch desativado fica cinza, para facilitar a leitura do estado.

    Alternar a cada 30 segundos

Exibe o limite semanal e o de 5 horas alternadamente. Quando a alternância está ativa, `Começar pela janela de 5 horas` define qual aparece primeiro; quando está desligada, o mesmo switch seleciona o único limite exibido.

    Modo compacto na barra

Reduz o texto da barra para `S 42%` em português ou `W 42%` em inglês no limite semanal, e para `5h 80%` na janela de 5 horas. O texto completo continua disponível na dica e no menu.

    Ocultar até fechar o Codex

Fecha o indicador e evita que o supervisor o abra novamente enquanto o Codex continuar aberto. Ao fechar o Codex, essa pausa é removida automaticamente.

A consulta de dados ao Codex ocorre a cada 5 minutos. Os contadores de renovação são redesenhados a cada 30 segundos usando os horários já recebidos, sem fazer uma nova consulta a cada redesenho. A alternância da barra, quando ativada, usa esse mesmo redesenho de 30 segundos.

## Privacidade e autenticação

O repositório não contém credenciais, tokens, limites ou dados da conta. O aplicativo consulta o app-server local do Codex usando a sessão que já está autenticada no Mac de cada usuário. O indicador não possui um servidor próprio, telemetria ou destino para enviar os limites.

O indicador e a preferência de exibição são locais. Se outra pessoa instalar o projeto, ela verá os limites da própria conta do Codex.

## Verificação

Para compilar e verificar a instalação localmente, com o Codex aberto e autenticado, execute:

    ./Scripts/build-app.sh
    "./dist/Codex Limite.app/Contents/MacOS/CodexWeeklyLimit" --check

## Desinstalação

Na pasta do projeto, execute:

    ./Scripts/uninstall.sh

Isso remove o aplicativo, o supervisor e o LaunchAgent desta conta do macOS.

## Publicação no GitHub

Para compartilhar o recurso, publique apenas o conteúdo deste repositório. Não publique a instalação atual do usuário, arquivos de `~/Library` ou a pasta inteira do workspace.

O fluxo recomendado é distribuir o código e o instalador, permitindo que cada Mac compile sua própria versão arm64. Uma GitHub Release com um app pronto também é possível, mas uma distribuição pública deve usar assinatura e notarização da Apple para reduzir alertas do Gatekeeper.

O arquivo ZIP é apenas um snapshot opcional do código e deve ser anexado a uma Release quando necessário, em vez de ser versionado junto com a fonte. Não publique a pasta `.claude/`, o aplicativo instalado ou qualquer arquivo de `~/Library`.

A API usada para ler limites é fornecida pelo aplicativo local do Codex e pode mudar em versões futuras.

## Licença

Este projeto é distribuído sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE).
