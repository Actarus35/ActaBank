FROM python:3.14-slim

# Pas de fichier .pyc, logs affichés immédiatement (pas de buffer)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Dépendance d'abord : cette couche est mise en cache tant que requirement.txt ne change pas (builds bien plus rapides ensuite)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Puis le code
COPY . .

# Utilisateur non-root : on ne fait jamais tourner un serveur exposé en root
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]