String? validateRequired(String? value, [String field = 'Campo']) {
  if (value == null || value.trim().isEmpty) {
    return '$field obrigatorio';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'E-mail obrigatorio';
  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!regex.hasMatch(value.trim())) return 'E-mail invalido';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Senha obrigatoria';
  if (value.length < 6) return 'Senha deve ter pelo menos 6 caracteres';
  return null;
}

String? validateCpfCnpj(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 11 && digits.length != 14) {
    return 'CPF ou CNPJ invalido';
  }
  return null;
}

String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 10 || digits.length > 11) {
    return 'Telefone invalido';
  }
  return null;
}
