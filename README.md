# Nginx Chef Controller

## Tutorial de uma configuração simples de serviços web

### Configurando sua infraestrutura

Primeiramente é necessário possuir _hosts_ Linux nos quais os diferentes serviços serão instalados. É possível construir uma infraestrutura simples de diferentes maneiras, com computadores pessoais, raspberryes, ou simplesmente contratando um serviço externo, como máquinas virtuais na Digital Ocean, Amazon EC2, Google Cloud, etc.

Existem várias vantagens de se manter servidores físicos, entretanto, há fatores limitantes que devem ser considerados antes de optar por um cluster de computadores pessoais, ou de microprocessadores. Um dos principais é o fato de que mesmo depois de você possuir o _hardware_ necessário, ainda necessitará de algum modo configurar o acesso externo aos serviços _web_ instalados. Existem algumas maneiras de se fazer isso sem ter que comprar um IP externo de sua operadora de Internet. A forma mais comum é configurar um serviço de [DDNS](https://en.wikipedia.org/wiki/Dynamic_DNS) (_Dynamic Domain Name Server_). O [NO-IP](https://www.noip.com/pt-BR) é um dos provedores mais famosos e possui suporte em diversos dispositivos _Modem_. O ponto negativo é ter que pagar caso deseje um domínio próprio. Nesse caso, existem diversas implementações de _softwares_ que utilizam diretamente as _APIs_ dos servidores DNS para alterar dinamicamente o seu IP global vinculado ao domínio assim que é verificado uma alteração forçada de seu IP pelo DHCP de sua operadora. Implemetei em _Python_ um sistema para o DNS do Gandi.net ([veja o repositório](https://github.com/luanguimaraesla/gandi-ddns)).

Os serviços em nuvem garantem uma estabilidade muito maior e, além disso, vários deles já contém uma série de recursos de monitoramento, intranet, DNS, etc. Então, apesar de ter um custo mais elevado para pequenas aplicações, pode ser uma boa escolha para evitar o trabalho manual de se manter uma infraestrutura local.

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

* `config/hosts/ips.yaml`: esse arquivo segue o formato chave-valor e deve conter como chave o apelido de cada serviço _web_ e o IP do _host_ onde é executado (**deve ser acessível para a máquina onde rodaremos o nosso _proxy_ reverso**). Também coloque o a chave `nginx: <ip-do-nginx-server>` para descrever em qual servidor as receitas que configuram o NGINX e o Letsencrypt serão executadas. Não tem problema se você estiver rodando os serviços na mesma máquina do NGINX, coloque os mesmos IPs para apelidos diferentes. Exemplo:

```
default: 10.0.0.102
rocketchat: 10.0.0.101
outrosite: 10.0.0.104
nginx: 10.0.0.104
```
