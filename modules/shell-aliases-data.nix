{
  nixrs = "git -C /home/cloudygirl/nixos add -A && nh os switch";
  ncg = "nh clean all";
  rollback = "nh os rollback";
  nixinfo = "nh os info";
  gitupdate = "git add . && git commit -m 'update' && git push";
  codenix = "z /nixos && code .";
  # eza：不覆盖 ls，沿用原 ls
  ll = "eza -lh --group-directories-first --icons";
  la = "eza -lah --group-directories-first --icons";
  lt = "eza --tree --level=2 --group-directories-first --icons";
  # bat：不覆盖 cat，需要时用 bcat
  bcat = "bat --style=plain --paging=never";
}
