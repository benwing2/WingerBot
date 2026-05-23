#!/usr/bin/env python3

import requests, os, re, sys, json

url_prefix = "https://spjs.ijppan.pl/haslo/index/"
output_prefix = "/Users/benwing/Documents/WingerBot/ijppan/"
subkey_file = output_prefix + "subkeys.json"
main_files_dir = output_prefix + "main-files/"
sub_files_dir = output_prefix + "subfiles/"
json_data_file = output_prefix + "data.json"
tsv_data_file = output_prefix + "data.tsv"

first_index = 1
last_index = 23425

columns = [
  "filename",
  "url",
  "title",
  "Typ",
  "Rodzaj",
  "Numer",
  "Definicja",
  "Gramatyka",
  "Semantyka",
  "Przykład w transliteracji",
  "Przykład w transkrypcji",
  "Lokalizacja",
]

def download_main_pages():
  for index in range(first_index, last_index + 1):
    url = url_prefix + str(index)
    print("Requesting %s ..." % url, end="")
    response = requests.get(url)
    print(" response: %s" % response.status_code)
    if response.status_code == 200:
      html_content = response.text
      outfile = "%s%s.html" % (main_files_dir, index)
      with open(outfile, "w", encoding="utf-8") as fp:
        fp.write(html_content)

def create_key_index():
  html_files = os.listdir(main_files_dir)
  keys_by_index_file = {}
  for html_file in html_files:
    if html_file.endswith(".html"):
      full_html_file = os.path.join(main_files_dir, html_file)
      with open(full_html_file, "r") as fp:
        contents = fp.read()
        keys_m = re.search('<div class="keys".*?>(.*?)</div>', contents)
        keys = []
        if not keys_m:
          print("%s: Couldn't find keys" % html_file, file=sys.stderr)
        else:
          key_spans = keys_m.group(1)
          keys = re.findall("<span>([0-9]+)</span>", key_spans)
        keys_by_index_file[html_file] = keys
  with open(subkey_file, "w") as fp:
    for html_file, keys in sorted(list(keys_by_index_file.items()), key=lambda x: int(x[0][:-5])): # chop off .html ending
      file_item = {"file": html_file, "keys": keys}
      fp.write(json.dumps(file_item) + "\n")

def download_sub_pages():
  for line in open(subkey_file, "r"):
    file_item = json.loads(line.rstrip("\n"))
    index = file_item["file"][:-5] # chop off .html ending
    keys = file_item["keys"]
    if not keys:
      keys = ["NULL"]
    for keyind, key in enumerate(keys):
      subfile = "%s%06d-%03d-%s.html" % (sub_files_dir, int(index), keyind, key)
      if keyind == 0:
        print("Writing %s ..." % subfile, end="")
        with open(subfile, "w") as fp:
          pass
        print(" Done.")
      else:
        url = url_prefix + index + "/" + key
        print("Downloading %s ..." % url, end="")
        response = requests.get(url)
        print(" response: %s" % response.status_code)
        if response.status_code == 200:
          html_content = response.text
          with open(subfile, "w", encoding="utf-8") as fp:
            fp.write(html_content)

def parse_one_page(filename, contents):
  lines = contents.split("\n")
  title = None
  saw_properties = False
  in_properties = False
  m = re.search(r"^([0-9]+)-([0-9]+)-(.+)\.html", filename)
  main_file, subfile_order, subfile_index = m.groups()
  if not m:
    print("Can't parse filename: %s" % filename, file=sys.stderr)
  if subfile_index == "NULL":
    url = url_prefix + str(int(main_file))
  else:
    url = url_prefix + str(int(main_file)) + "/" + subfile_index
  props = {"filename": filename, "url": url}
  for lineno, line in enumerate(lines):
    if "artykuł hasłowy" in line:
      if title is not None:
        print("WARNING: %s: Saw title twice" % filename, file=sys.stderr)
      title = lines[lineno + 1].strip().replace("</h1>", "")
      props["title"] = title
    if '<table class="detail-view"' in line:
      in_properties = True
      if saw_properties:
        print("WARNING: %s: Saw property table twice" % filename, file=sys.stderr)
      saw_properties = True
    if in_properties and "</table>" in line:
      in_properties = False
    if in_properties:
      m = re.search("<th>(.*?)</th><td>(.*?)</td>", line)
      if m:
        key, value = m.groups()
        key = key.replace("<br/>", " ")
        if key in props:
          print("WARNING: %s: Saw key %s twice in property table" % (filename, key), file=sys.stderr)
        props[key] = value
  return props

def parse_pages():
  mainfiles = os.listdir(main_files_dir)
  subfiles = sorted(os.listdir(sub_files_dir))
  for subfile in subfiles:
    m = re.search(r"^([0-9]+)-([0-9]+)-(.+)\.html", subfile)
    main_file, subfile_order, subfile_index = m.groups()
    if not m:
      print("Can't parse filename: %s" % subfile, file=sys.stderr)
    else:
      full_subfile = os.path.join(sub_files_dir, subfile)
      with open(full_subfile, "r") as fp:
        contents = fp.read()
      if not contents:
        full_main_file = os.path.join(main_files_dir, str(int(main_file)) + ".html")
        # FIXME: Should catch error if file doesn't exist
        with open(full_main_file, "r") as fp:
          contents = fp.read()
      props = parse_one_page(subfile, contents)
      #print(json.dumps(props))
      tsv_values = []
      for column in columns:
        if column in props:
          tsv_values.append(props[column].replace("\t", r"\t").replace("\n", r"\n"))
        else:
          tsv_values.append("-")
      print("\t".join(tsv_values))

# download_main_pages()
# create_key_index()
# download_sub_pages()
parse_pages()
