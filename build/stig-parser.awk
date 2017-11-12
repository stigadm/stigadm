#!/usr/bin/awk

# Get the stig id
$0 ~ /<Group id=".*">/{
  gsub(/<Group id=/, "", $0);
  gsub(/"/, "", $0);
  gsub(/>/, "", $0);
  gsub(/-/, "00", $0);
  gsub(/  /, "", $0);
  stigid=$0;
  printf("%s:", stigid);
}

# Convert the classification
$0 ~ /Rule id=".*"/ {
  rblob=$3
  gsub(/severity=/, "", rblob);
  gsub(/low/, "CAT-III", rblob);
  gsub(/medium/, "CAT-II", rblob);
  gsub(/high/, "CAT-I", rblob);
  gsub(/"/, "", rblob);
  cat=rblob;
  printf("%s:", cat);
}

# Get the stig version
$0 ~ /<version>.*<\/version>$/{
  gsub(/<version>/, "", $0);
  gsub(/<\/version>/, "" $0);
  gsub(/</, "" $0);
  gsub(/    /, "", $0);
  stigver=$1
  printf("%s:", stigver);
}

$0 ~ /Rule id=".*"/{
  gsub(/<Rule id=/, "", $0);
  gsub(/"/, "", $0);
  gsub(/>/, "", $0);
  gsub(/_rule/, "", $0);
  ruleid=$1;
  printf("%s:", ruleid);
}

$0 ~ /<title>.*<\/title>$/ && $0 !~ /SRG/ {
  blob=$0;
  gsub(/<*title>/, "", blob);
  gsub(/<\//, "", blob);
  gsub(/      /, "", blob);
  gsub(/    /, "", $0);
  gsub(/ /, "~", blob);
  printf("%s:", blob);
}

$0 ~ /<description>.*<\/description>$/ && $0 !~ /GroupDescription/{
  blob=$0;
  gsub(/<description>&lt;VulnDiscussion/, "", blob);
  gsub(/&lt;.*VulnDiscussion.*/, "", blob);
  gsub(/&gt;/, "", blob);
  gsub(/      /, "", blob);
  gsub(/ /, "~", blob);
  printf("%s:", blob);
}

$0 ~ /<dc:subject>.*<*dc:subject>$/{
  gsub(/<dc:subject>/, "", $0);
  gsub(/<\/dc:subject>/, "", $0);
  gsub(/Red Hat/, "Red_Hat", $0);
  gsub(/Oracle Linux/, "Oracle_Linux", $0);
  printf("%s:%s:%s\n", $1, $2, $3);
}
