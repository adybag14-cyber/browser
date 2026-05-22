$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Win32Input.ps1")

function Get-HeadedMailboxPrintableKeySpec([char]$Char) {
  $codePoint = [int][char]$Char

  if ($codePoint -ge [int][char]'a' -and $codePoint -le [int][char]'z') {
    return @{
      Code = [int][char]([char]::ToUpperInvariant($Char))
      Modifiers = 0
      Text = [string]$Char
    }
  }

  if ($codePoint -ge [int][char]'A' -and $codePoint -le [int][char]'Z') {
    return @{
      Code = $codePoint
      Modifiers = 1
      Text = [string]$Char
    }
  }

  if ($codePoint -ge [int][char]'0' -and $codePoint -le [int][char]'9') {
    return @{
      Code = $codePoint
      Modifiers = 0
      Text = [string]$Char
    }
  }

  switch ([string]$Char) {
    ' ' { return @{ Code = 32; Modifiers = 0; Text = ' ' } }
    '-' { return @{ Code = 45; Modifiers = 0; Text = '-' } }
    '_' { return @{ Code = 45; Modifiers = 1; Text = '_' } }
    '=' { return @{ Code = 61; Modifiers = 0; Text = '=' } }
    '+' { return @{ Code = 61; Modifiers = 1; Text = '+' } }
    ',' { return @{ Code = 44; Modifiers = 0; Text = ',' } }
    '<' { return @{ Code = 44; Modifiers = 1; Text = '<' } }
    '.' { return @{ Code = 46; Modifiers = 0; Text = '.' } }
    '>' { return @{ Code = 46; Modifiers = 1; Text = '>' } }
    '/' { return @{ Code = 47; Modifiers = 0; Text = '/' } }
    '?' { return @{ Code = 47; Modifiers = 1; Text = '?' } }
    ';' { return @{ Code = 59; Modifiers = 0; Text = ';' } }
    ':' { return @{ Code = 59; Modifiers = 1; Text = ':' } }
    "'" { return @{ Code = 39; Modifiers = 0; Text = "'" } }
    '"' { return @{ Code = 39; Modifiers = 1; Text = '"' } }
    '[' { return @{ Code = 91; Modifiers = 0; Text = '[' } }
    '{' { return @{ Code = 91; Modifiers = 1; Text = '{' } }
    ']' { return @{ Code = 93; Modifiers = 0; Text = ']' } }
    '}' { return @{ Code = 93; Modifiers = 1; Text = '}' } }
    '\' { return @{ Code = 92; Modifiers = 0; Text = '\' } }
    '|' { return @{ Code = 92; Modifiers = 1; Text = '|' } }
    '`' { return @{ Code = 96; Modifiers = 0; Text = '`' } }
    '~' { return @{ Code = 96; Modifiers = 1; Text = '~' } }
    '!' { return @{ Code = 49; Modifiers = 1; Text = '!' } }
    '@' { return @{ Code = 50; Modifiers = 1; Text = '@' } }
    '#' { return @{ Code = 51; Modifiers = 1; Text = '#' } }
    '$' { return @{ Code = 52; Modifiers = 1; Text = '$' } }
    '%' { return @{ Code = 53; Modifiers = 1; Text = '%' } }
    '^' { return @{ Code = 54; Modifiers = 1; Text = '^' } }
    '&' { return @{ Code = 55; Modifiers = 1; Text = '&' } }
    '*' { return @{ Code = 56; Modifiers = 1; Text = '*' } }
    '(' { return @{ Code = 57; Modifiers = 1; Text = '(' } }
    ')' { return @{ Code = 48; Modifiers = 1; Text = ')' } }
  }

  return $null
}

function Send-HeadedMailboxNativePrintableText([string]$Text) {
  if (-not (Use-HeadedMailboxInput)) {
    throw "Headed mailbox input is not enabled"
  }

  foreach ($ch in $Text.ToCharArray()) {
    $codePoint = [int][char]$ch
    if ($codePoint -eq 10 -or $codePoint -eq 13) {
      Send-HeadedKeyStroke -Code 13
      continue
    }

    $spec = Get-HeadedMailboxPrintableKeySpec $ch
    if ($null -eq $spec) {
      [void](Write-HeadedMailboxLine ("text|{0}" -f [string]$ch))
      continue
    }

    [void](Write-HeadedMailboxLine ("key|{0}|1|{1}" -f $spec.Code, $spec.Modifiers))
    [void](Write-HeadedMailboxLine ("text|{0}" -f $spec.Text))
    [void](Write-HeadedMailboxLine ("key|{0}|0|{1}" -f $spec.Code, $spec.Modifiers))
  }
}

function Send-SmokeMailboxNativePrintableText([string]$Text) {
  Send-HeadedMailboxNativePrintableText -Text $Text
}
