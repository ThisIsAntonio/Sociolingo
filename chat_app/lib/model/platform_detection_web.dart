// Importa dart:js solo para la web
import 'dart:js' as js;

bool isIOSDevice() {
  return js.context.hasProperty('isIOSDevice') &&
      js.context['isIOSDevice'] as bool;
}
