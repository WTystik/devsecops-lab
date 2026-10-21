# DevSecOps lab

Flask-приложение с локальным конвейером тестирования, сборки, проверки безопасности и публикации Docker-образов. Для сравнения используются три варианта: `insecure`, `latest` и `distroless`.

## Компоненты

- `app/` — приложение, тесты, зависимости и Dockerfile.
- `scripts/pipeline.sh` — тесты, анализ Dockerfile, сборка, сканирование образа и публикация.
- `infrastructure/` — Ubuntu 22.04 в VirtualBox и скрипты подготовки Docker, Trivy и приватного реестра.
- `.github/workflows/ci-cd.yml` — тестирование, сборка и сканирование в GitHub Actions.

Trivy закреплён на версии `0.76.0`; архив проверяется по SHA-256. Версии Flask и Gunicorn указаны в `app/requirements.txt`.

## Локальный запуск

Команды выполняются из корня проекта в Bash. На Windows `host-env.sh` подключает локальное окружение Python и добавляет инструменты в PATH.

```bash
source scripts/host-env.sh
cd infrastructure
vagrant up
cd ..
bash scripts/pipeline.sh
```

Приватный реестр доступен по адресу `192.168.56.10:5000`. Для учебного HTTP-реестра этот адрес должен быть указан в `insecure-registries` Docker Engine на хосте.

## Варианты образа

```bash
bash scripts/pipeline.sh Dockerfile.insecure insecure
bash scripts/pipeline.sh Dockerfile latest
bash scripts/pipeline.sh Dockerfile.distroless distroless
```

Вариант `insecure` предназначен для проверки блокировки небезопасной конфигурации. Публикация выполняется только после прохождения проверок. Политика по умолчанию блокирует HIGH/CRITICAL в Dockerfile и исправимые HIGH/CRITICAL в образе. Полный результат сканирования сохраняется в `reports/`.

## Подготовка виртуальной машины

Рабочий `infrastructure/Vagrantfile` подключает проект в `/home/vagrant/devsecops-lab`, устанавливает Docker и Trivy, создаёт Linux-окружение Python и запускает `registry:3` с томом `registry-data`. Шаблон этой конфигурации находится в `Vagrantfile.automated`.

Запуск конвейера внутри подготовленной VM:

```bash
cd infrastructure
vagrant ssh -c "cd /home/vagrant/devsecops-lab && bash scripts/pipeline.sh"
```

GitHub Actions выполняет тесты и проверки образа без публикации в локальный реестр VM.

