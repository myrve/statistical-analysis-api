library(plumber)

# API dosyasını çalıştır
api <- plumb("api.R")  # api.R, API kodunuzu içeren dosyanın adı
api$run(host="0.0.0.0", port=8000)
