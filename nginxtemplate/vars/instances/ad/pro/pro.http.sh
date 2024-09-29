# echo $(dirname $0)
ytt -f $(dirname $0)/../base/config.http.example.yaml -f $(dirname $0)/overlay.yaml 