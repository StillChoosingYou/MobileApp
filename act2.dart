// ===============================
// Activity 5 - Product Class
// ===============================
class Product {
  String name;
  double price;
  int quantity;

  Product(this.name, this.price, this.quantity);

  double calculateTotal() {
    return price * quantity;
  }
}

// ===============================
// Activity 6 - Student Class
// ===============================
class Student {
  String name;
  int age;
  String? email;

  Student(this.name, this.age, {this.email});

  void displayInfo() {
    print('Name: $name');
    print('Age: $age');
    print('Email: ${email ?? "No email provided"}');
  }
}

// ===============================
// Activity 4 - Function
// ===============================
double calculateArea(double length, double width) {
  return length * width;
}

// ===============================
// Main Program
// ===============================
void main() {
  // =====================================
  // Activity 1
  // =====================================
  print('========== Activity 1 ==========');

  String studentName = 'Juan Dela Cruz';
  int studentAge = 20;
  double average = 91.75;
  bool isEnrolled = true;
  List<String> subjects = [
    "Mobile Application Development",
    "Statistics",
    "Intelligent Systems"
  ];

  print('Student Name: $studentName');
  print('Age: $studentAge');
  print('Average: $average');
  print('Enrollment Status: $isEnrolled');
  print('Subjects: $subjects');

  // =====================================
  // Activity 2
  // =====================================
  print("\n========== Activity 2 ==========");

  int grade = 87;

  if (grade >= 90) {
    print("Grade: A");
  } else if (grade >= 80) {
    print("Grade: B");
  } else if (grade >= 70) {
    print("Grade: C");
  } else if (grade >= 60) {
    print("Grade: D");
  } else {
    print("Grade: F");
  }

  // =====================================
  // Activity 3
  // =====================================
  print("\n========== Activity 3 ==========");

  for (int i = 1; i <= 10; i++) {
    print("5 x $i = ${5 * i}");
  }

  // =====================================
  // Activity 4
  // =====================================
  print("\n========== Activity 4 ==========");

  double area = calculateArea(8, 5);
  print("Area of Rectangle: $area");

  // =====================================
  // Activity 5
  // =====================================
  print("\n========== Activity 5 ==========");

  Product product = Product("Laptop", 35000, 2);

  print("Product Name: ${product.name}");
  print("Price: ${product.price}");
  print("Quantity: ${product.quantity}");
  print("Total: ${product.calculateTotal()}");

  // =====================================
  // Activity 6
  // =====================================
  print("\n========== Activity 6 ==========");

  Student student1 =
      Student("Jake", 21, email: "jake@gmail.com");

  Student student2 =
      Student("Maria", 20);

  student1.displayInfo();

  print("");

  student2.displayInfo();
}