#!/usr/bin/python3

def bin2word(bin_file, word_txt):
  word_list = []
  with open(bin_file, mode='rb') as f:
    data = f.read()
    word = 0
    byte_num = len(data)
    for i, byte in enumerate(data):
      if (i % 4) == 0:
        word = byte
      else:
        word |= (byte << (i % 4) * 8)
      if (i % 4) == 3 or i == (byte_num - 1):
        word_list.append(f"{word:x}")
  with open(word_txt, mode='w') as f:
    for word in word_list:
      f.write(word + '\n')


if __name__ == "__main__":
  import sys
  assert len(sys.argv) >= 3, "usage: ./bin2word.py bin_file output_file"
  bin_file = sys.argv[1]
  word_txt = sys.argv[2]
  print(f"bin_file: {bin_file}")
  print(f"output: {word_txt}")
  bin2word(bin_file, word_txt)
