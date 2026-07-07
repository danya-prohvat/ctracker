import Foundation

/// How `NewProductForm` is used (spec §5).
enum ProductFormMode {
    case logging            // from "+": primary continues to the quantity screen
    case saving             // create & save only (from My products management)
    case editing(Product)   // edit an existing product
}
