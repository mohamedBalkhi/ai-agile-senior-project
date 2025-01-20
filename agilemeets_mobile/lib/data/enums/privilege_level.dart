enum PrivilegeLevel {
  none(0, 'None'),
  read(1, 'Read'),
  write(2, 'Write');

  final int value;
  final String label;
  
  const PrivilegeLevel(this.value, this.label);

  static PrivilegeLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'write':
        return PrivilegeLevel.write;
      case 'read':
        return PrivilegeLevel.read;
      default:
        return PrivilegeLevel.none;
    }
  }

  bool get canRead => this != PrivilegeLevel.none;
  bool get canWrite => this == PrivilegeLevel.write;
} 