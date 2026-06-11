# devtool MongoDB (Bitnami)

- Namespace: `devtool`
- Release: `mongo`
- Service: `mongo-mongodb.devtool.svc.cluster.local:27017`
- DB user: `antiweb` / database `blog`

```bash
npm run helm:devtool:secrets
npm run helm:devtool:install:mongodb
npm run deploy:mongodb:restore
```

비밀번호: 28자 영숫자 (`helm/devtool/scripts/devtool-secrets-generate.sh`)
