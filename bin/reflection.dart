// Example showing how to modify a soia value held in RAM using reflection.
//
// Run with:
//   dart run bin/reflection.dart

import 'package:soia/soia.dart' as soia;
import 'package:soia_dart_example/soiagen/loot_box.dart';

void main() {
  final lootResultWithDebug = LootResult.wrapSuccess(
    LootPayload(
      transactionId: 'tx-12345',
      luckModifier: 1.5,
      awardedItems: [
        LootPayload_Item(
          itemId: 101,
          name: 'Golden Sword',
          rarityLevel: 5,
          debug: LootPayload_Item_Debug(
            log: 'Item generated successfully.',
          ),
        ),
      ],
      debug: LootPayload_Debug(
        generationDurationMs: 42,
      ),
    ),
  );

  final actualClearedLootResult = clearDebugFields(
    lootResultWithDebug,
    LootResult.serializer.typeDescriptor,
  );

  final expectedClearedLootResult = LootResult.wrapSuccess(
    LootPayload(
      transactionId: 'tx-12345',
      luckModifier: 1.5,
      awardedItems: [
        LootPayload_Item(
          itemId: 101,
          name: 'Golden Sword',
          rarityLevel: 5,
          debug: LootPayload_Item_Debug(
            log: '',
          ),
        ),
      ],
      debug: LootPayload_Debug(
        generationDurationMs: 0,
      ),
    ),
  );

  if (actualClearedLootResult != expectedClearedLootResult) {
    throw Exception(
        'Debug fields were not cleared properly: $actualClearedLootResult');
  }
}

/// Returns a copy of [input] with all 'debug' fields cleared to their default
/// values.
T clearDebugFields<T>(T input, soia.ReflectiveTypeDescriptor<T> descriptor) {
  final visitor = _ClearDebugVisitor<T>(input);
  descriptor.accept(visitor);
  return visitor.result;
}

class _ClearDebugTransformer implements soia.ReflectiveTransformer {
  const _ClearDebugTransformer();

  @override
  T transform<T>(T input, soia.ReflectiveTypeDescriptor<T> descriptor) {
    return clearDebugFields(input, descriptor);
  }
}

class _ClearDebugVisitor<T> extends soia.NoopReflectiveTypeVisitor<T> {
  final T input;
  T result;

  _ClearDebugVisitor(this.input) : result = input;

  @override
  void visitOptional<NotNull>(
      soia.ReflectiveOptionalDescriptor<NotNull> descriptor,
      soia.TypeEquivalence<T, NotNull?> equivalence) {
    result = equivalence.toT(
      descriptor.applyTransformer(
        equivalence.fromT(input),
        const _ClearDebugTransformer(),
      ),
    );
  }

  @override
  void visitArray<E, Collection extends Iterable<E>>(
      soia.ReflectiveArrayDescriptor<E, Collection> descriptor,
      soia.TypeEquivalence<T, Collection> equivalence) {
    result = equivalence.toT(
      descriptor.applyTransformer(
        equivalence.fromT(input),
        const _ClearDebugTransformer(),
      ),
    );
  }

  @override
  void visitStruct<Mutable>(
      soia.ReflectiveStructDescriptor<T, Mutable> descriptor) {
    final mutable = descriptor.newMutable();
    for (final field in descriptor.fields) {
      if (field.name != 'debug') {
        field.copy(
          input,
          mutable,
          transformer: const _ClearDebugTransformer(),
        );
      }
    }
    result = descriptor.toFrozen(mutable);
  }

  @override
  void visitEnum(soia.ReflectiveEnumDescriptor<T> descriptor) {
    result = descriptor.applyTransformer(
      input,
      const _ClearDebugTransformer(),
    );
  }
}
