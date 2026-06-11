# imustdo.work blog — Kubernetes / Argo CD 배포

playstyle.lol 클러스터에 `blog` 네임스페이스로 배포합니다. playstyle.lol 레포 파일은 수정하지 않습니다.

## 사전 요구

- kubectl, helm, mongosh/mongorestore (restore 시)
- playstyle devtool: Redis, Harbor, Argo CD, Istio Gateway
- Argo CD에 `git@github.com:slowquery/blog` repo 등록
- GitHub Secrets: `HARBOR_USER`, `HARBOR_PASSWORD`

## 이미지

```
image.registry.playstyle.lol/blog/application:{semver}
```

## 배포 순서

```bash
npm run harbor:project          # Harbor blog 프로젝트 생성
npm run helm:devtool:secrets
npm run helm:devtool:install:mongodb
npm run deploy:mongodb:restore  # dump.zip → MongoDB
cp deploy/.env.app.example deploy/.env.app  # SECRET_KEY 등
npm run deploy:argocd           # secrets + Argo Application
npm run deploy:upload:sync      # upload/ → PVC
npm run deploy:gateway-hosts    # imustdo.work Gateway hosts
```

DNS 변경 전 검증 (in-cluster만):

```bash
npm run deploy:verify
```

DNS 변경 후 외부 검증 (사용자 확인 후):

```bash
VERIFY_EXTERNAL_DNS=1 npm run deploy:verify
```

마이그레이션 완료 (검증 통과 후 dump.zip 삭제·커밋):

```bash
npm run deploy:finish
git push origin master
```

## Istio

| Host | Backend |
|------|---------|
| `imustdo.work`, `www.imustdo.work` | `application.blog:9000` |

Gateway 호스트는 `deploy:gateway-hosts`로 patch합니다. playstyle Argo CD가 Gateway를 재적용하면 호스트가 사라질 수 있습니다.

## Secret

`deploy/scripts/sync-app-secrets.sh` → `blog-app-env` Secret (`blog` NS)

- MongoDB: blog `helm/devtool/.env.devtool`
- Redis: playstyle `helm/devtool/.env.devtool` (공유 devtool Redis)
