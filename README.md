# Nginx Chef Controller

## Tutorial de uma configuração simples de serviços web

### Configurando sua infraestrutura

Primeiramente é necessário possuir _hosts_ Linux nos quais os diferentes serviços serão instalados. É possível construir uma infraestrutura simples de diferentes maneiras, com computadores pessoais, raspberryes, ou simplesmente contratando um serviço externo, como máquinas virtuais na Digital Ocean, Amazon EC2, Google Cloud, etc.

Existem várias vantagens de se manter servidores físicos, entretanto, há fatores limitantes que devem ser considerados antes de optar por um cluster de computadores pessoais, ou de microprocessadores. Um dos principais é o fato de que mesmo depois de você possuir o _hardware_ necessário, ainda necessitará de algum modo configurar o acesso externo aos serviços _web_ instalados. Existem algumas maneiras de se fazer isso sem ter que comprar um IP externo de sua operadora de Internet. A forma mais comum é configurar um serviço de [DDNS](https://en.wikipedia.org/wiki/Dynamic_DNS) (_Dynamic Domain Name Server_). O [NO-IP](https://www.noip.com/pt-BR) é um dos provedores mais famosos e possui suporte em diversos dispositivos _Modem_. O ponto negativo é ter que pagar caso deseje um domínio próprio. Nesse caso, existem diversas implementações de _softwares_ que utilizam diretamente as _APIs_ dos servidores DNS para alterar dinamicamente o seu IP global vinculado ao domínio assim que é verificado uma alteração forçada de seu IP pelo DHCP de sua operadora. Implemetei em _Python_ um sistema para o DNS do Gandi.net ([veja o repositório](https://github.com/luanguimaraesla/gandi-ddns)).

Os serviços em nuvem garantem uma estabilidade muito maior e, além disso, vários deles já contém uma série de recursos de monitoramento, intranet, DNS, etc. Então, apesar de ter um custo mais elevado para pequenas aplicações, pode ser uma boa escolha para evitar o trabalho manual de se manter uma infraestrutura local.

Na maioria das vezes, você precisará apenas redirecionar um _wildcard_ para o servidor onde rodará o NGINX, o _proxy_ reverso que iremos configurar. Desta forma, altere as regras de seu DNS para que `*.seudominio.com` aponte para o IP da máquina onde iremos configurar o _proxy_ reverso. Você também pode optar por só redirecionar alguns domínios, por exemplo: `chat.seudominio.com`, `blog.seudominio.com`. De qualquer forma, todos eles devem apontar para o IP do _proxy_ reverso.

Após a configuração de seu domínio em algum serviço de DNS, verifique se o mesmo já propagou para o resto dos servidores no mundo. Isso é extremamente importante para que possamos garantir que o Letsencrypt, serviço que usaremos para gerar os certificados dos nossos _sites_, encontrará os domínios e subdomínios no processo de geração. Utilize [este site](https://www.whatsmydns.net/) para fazer essa verificação.

### Configurando seus seviços

Agora você pode configurar normalmente os seus sistemas nos servidores locais ou virtualizados externamente. Lembre-se de que iremos precisar da porta 80 e 443 de uma das máquinas para rodar o NGINX como nosso _proxy_ reverso. Assim, aconselho utilizar outras portas, como a 8080, 8000, 5000 para rodar os serviços.

Garanta que localmente e na intranet (caso haja mais de um servidor) os serviços estão acessíveis com _telnet_, _wget_, _curl_, _netstat_ ou outro programa.

### Configuração do CHAKE/CHEF

O [Chake](https://github.com/terceiro/chake) é um serviço utilizado para gerenciar diversos _hosts_ com o [Chef](https://www.chef.io/chef/) sem a necessidade do _chef-server_. Leia sua [documentação](https://github.com/terceiro/chake) para compreender os arquivos de configuração e como utilizar o Chake.

Em resumo, precisaremos de um _host_ que gerenciará nossos outros servidores. Podemos utilizar nosso computador pessoal como _host_ principal, onde instalaremos o chake.

```bash
gem install chake
```

Este repositório contém as receitas CHEF necessárias para configurar o **NGINX** como _proxy_ reverso e executar o _Certbot_ do **Letsencrypt** para gerar os certificados de cada serviço _web_ desejado. Clone este repositório.

```bash
git clone https://gitlab.com/luanguimaraesla/nginx-chef-controller
```

Agora precisamos configurar os nossos domínios, IPs e portas para que as receitas possam ser executadas corretamente, gerando os respectivos arquivos a partir dos _templates_ previamente escritos.

Edite os sequintes arquivos de configuração:

* `config/hosts/ips.yaml`: esse arquivo segue o formato chave-valor e deve conter como chave o apelido de cada serviço _web_ e o IP do _host_ onde é executado (**deve ser acessível para a máquina onde rodaremos o nosso _proxy_ reverso**). Também coloque a chave "_nginx: <ip-do-nginx-server>_" para descrever em qual servidor as receitas que configuram o NGINX e o Letsencrypt serão executadas. Não tem problema se você estiver rodando os serviços na mesma máquina do NGINX, coloque os mesmos IPs para apelidos diferentes. Exemplo:

```yaml
# config/hosts/ips.yaml
# configuration example
default: 10.0.0.102
rocketchat: 10.0.0.101
outrosite: 10.0.0.104
nginx: 10.0.0.104
```

**IMPORTANTE**: o **_default_** é o serviço raiz, ou seja, aquele no qual o restante dos subdomínios certificados estará vinculado e para o qual será efetuado o redirecionamento para tentativas de acesso a subdomínios inválidos. Desta forma, se você irá criar os domínios _chat.exemplo.com_, _blog.exemplo.com_ e _exemplo.com_, este último provavelmente será o site principal e, portanto, deve ser o serviço _default_. Apesar disso, não é necessário possuir um serviço _default_, você pode omitir essa configuração e comentar a última linha do arquivo `cookbooks/letsencrypt/recipes/default.rb`.

* `config/hosts/ssh_config`: esse é o arquivo de configuração de acesso SSH em cada host. Não é necessário, mas facilita, utilizar os mesmos apelidos dados aos serviços. Exemplo:

```
Host default
  Hostname 10.0.0.102
  User root

Host rocketchat
  Hostname 10.0.0.101
  User rocketchat

Host outrosite
  Hostname 10.0.0.104
  User guest

Host nginx
  Hostname 10.0.0.104
  User root
```

**IMPORTANTE**: para que as receitas possam ser executadas corretamente, o usuário utilizado em cada _host_ deve ter poderes de executar comandos privilegiados sem usar senha. Altere o arquivo `/etc/sudoers`:

```bash
visudo
```

O acesso via SSH a este usuário também deve ser feito sem a necessidade de senha. Para isso copie sua chave pública SSH para o arquivo `/home/<user>/.ssh/authorized_keys`. Se não existir esse caminho nos _hosts_, crie-os da seguinte maneira:

```bash
mkdir -m 700 -p ~/.ssh
echo "<your-ssh-public-key>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

* `config/hosts/certificate_domains.yaml`: esse arquivo é utilizado em conjunto com o `ips.yaml` para criar os templates dos servidores para os quais o _proxy_ reverso redirecionará, assim, para cado apelido registrado neste arquivo, você deverá descrever a porta em que o serviço é executado e seu respectivo subdomínio. De acordo com o exemplo dado acima para o arquivo _ips.yaml_, criaríamos o seguinte arquivo de certificados:

```yaml
# config/hosts/certificate_domains.yaml
# configuration example
default:
  server_name: exemplo.org
  service_port: 80

rocketchat:
  server_name: chat.exemplo.org
  service_port: 3000

outrosite:
  server_name: outrosite.exemplo.org
  service_port: 8080
```

Observe que não existe a chave `nginx`. Ela não é necessária porque o NGINX atua apenas como um _proxy_ reverso, não possui um domínio vinculado.

### Utilizando o Chake

O _Chake_ é uma abstração do _Ruby Rake_. Assim, podemos utilizar o próprio comando `rake` para executar as tarefas preconfiguradas no _Chake_.

#### Testando a conexão

Para testar se as conexões estão funcionando adequadamente, utilize o seguinte comando no servidor de controle onde o _Chake_ está instalado e este repositório está clonado:

```bash
cd nginx-chef-controller
rake run['sudo date']
```

Esse comando irá executar o comando `sudo date` em todos os nós registrados. No nosso caso, apenas o **NGINX** pode ser enxergado como um nó. Caso este comando falhe, existe algum problema de conexão ou permissão com o usuário da máquina onde o _NGINX_ será configurado.

#### Executando as receitas

Caso o teste tenha finalizado com sucesso e os arquivos de configuração estejam prontos. Execute o comando:

```bash
rake converge:nginx
```

Esse comando demorará um pouco para executar. Ele irá instalar e configurar todo o ambiente de _proxy_ reverso com o _NGINX_ + Letsencrypt. Para que seja executado com sucesso, **garanta que todos os serviços _web_ estejam configurados e rodando nos IPs e portas especificadas nos arquivos de configuração**.

#### Login nos servidores

Você pode fazer o login em cada um dos servidores com o comando `rake login:<host>`. Por exemplo, para logar na máquina do _NGINX_ execute:

```bash
rake login:nginx
```

### Finalizando

Agora você já pode acessar com SSL todos os seus serviços web configurados. Caso tenha alguma dificuldade, por favor reporte o problema em uma [nova _issue_](https://gitlab.com/luanguimaraesla/nginx-chef-controller/issues) ou envie um email para `luang@protonmail.ch`.

### Outros tópicos

#### Renovação dos certificados

Você será notificado em 90 dias para renovar os certificados de seus sites. Existem maneiras de configurar um cronjob para fazer isso automaticamente ou você pode simplesmente reexecutar o comando `rake converge:nginx`.

#### Número limite de certificados

Para não exceder a quantidade de certificados que podem ser criados em uma semana com o _Letsencrypt_, existe um arquivo de trava para  negar a tentativa de atualização dos certificados caso nenhum domínio novo tenha sido adicionado aos arquivos de configuração. Assim, tanto para renovar os certificados depois de 90 dias, quanto para regerar os certificados criados por motivo de alguma falha, deve-se remover do servidor do _NGINX_ o arquivo `/etc/nginx.services`.

```bash
rake run:nginx["sudo rm -rf /etc/nginx.services"]
```

#### Configurações adicionais aos servers NGINX

Cada servidor possui um arquivo de configuração localizado em `/etc/nginx/sites-enabled`. Configurações específicas devem ser feitas manualmente.

```bash
rake login:nginx
cd /etc/nginx/sites-enabled
# edite os arquivos necessários
sudo systemctl restart nginx
```
