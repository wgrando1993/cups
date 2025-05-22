# Cups
### 📌 Sobre o Projeto
Uma compilação simples do cups com algumas alterações que para o meu contexto eram importantes, tais como:
1. Versão mais atualizada
2. Filtro para leitura de arquivos docx/xlsx
3. Suporte a Nomes para instalar impressoras ex: imp.escritorio
4. Pacote de drivers mais completo
---

### 🚀 Como Usar

#### Via docker compose (Meu preferido.)

```yaml
---
services:
  cups:
    image: grandow/cups:2.4.12-office
    container_name: cups
    restart: unless-stopped
    ulimits:
        nofile:
          soft: "65536"
          hard: "65536"
    ports:
        - "631:631"
    environment:
        - USERNAME=admin
        - PASSWORD=cups
        - TZ="America/Sao_Paulo"
    volumes:
        - "./cups/:/etc/cups/"
```
