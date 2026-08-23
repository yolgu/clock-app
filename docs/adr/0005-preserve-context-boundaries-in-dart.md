# Preserve Clock Rhythm context boundaries in Dart

The Flutter source will retain `app`, `contexts/rhythm`, `contexts/todo`, `contexts/preferences`, `features/data_transfer`, and domain-neutral `shared` boundaries without turning each context into a separate Dart package. Layers are created only where their responsibilities exist, dependencies point inward, Data Transfer orchestrates published context contracts, and Windows or Android capabilities are selected behind ports at the application composition root rather than through platform checks in Domain or ViewModels.
