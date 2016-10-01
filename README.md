# Rails Pointer

Trabalho TCC

Dependências:

* Ruby
* elasticsearch
* Mongodb

Este trabalho usa o elasticsearch como fonte de pesquisa, portanto faça o [download dele] e rode o serviço localmente antes de continuar.
[download dele]: <https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html>

Foi disponibilisado um arquivo "~/db/seeds/profiles.json" com oito perfis previamente extraidos.

Para inicializar abra o terminal no diretorio do projeto e execute:
```bundle install```, para instalar todas as gems necessárias.

Então, para popular o banco (tanto o mongoid quanto o elasticsearch) utilize o comando:
```rake db:setup```

Agora para iniciar o servidor: ```rails s```