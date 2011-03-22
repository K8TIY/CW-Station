#include <stdio.h>

static int is_vowel(char first_char);

char buffer[200];

char* A_Or_An(char* string)
{
  if (is_vowel (string[0]) == 1) sprintf (buffer, "an %s", string);
  else sprintf (buffer, "a %s", string);
  return ((char*)buffer);
}

static int is_vowel(char first_char)
{
  return (
  first_char == 'A' ||
  first_char == 'E' ||
  first_char == 'I' ||
  first_char == 'O' ||
  first_char == 'U' ||
  first_char == 'a' ||
  first_char == 'e' ||
  first_char == 'i' ||
  first_char == 'o' ||
  first_char == 'u'
  );
}
