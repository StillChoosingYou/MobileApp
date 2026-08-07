import 'dart:io';

// ===============================
// Activity 4 - Function
// ===============================
double calculateArea(double length, double width) {
  return length * width;
}

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
    print('Name : $name');
    print('Age  : $age');
    print("Email: ${email ?? "No email provided"}");
  }
}

// ===============================
// Main Program
// ===============================
void main() {
  int choice;

  do {
    print('\n======================================');
    print('      CLASSROOM PRACTICE ACTIVITIES');
    print('======================================');
    print('1. Activity 1 - Variables');
    print('2. Activity 2 - Grade Evaluation');
    print('3. Activity 3 - Multiplication Table');
    print('4. Activity 4 - Rectangle Area');
    print('5. Activity 5 - Product Class');
    print('6. Activity 6 - Student Class');
    print('0. Exit');
    print('======================================');

    stdout.write('Enter your choice: ');
    choice = int.tryParse(stdin.readLineSync() ?? '') ?? -1;

    print('');

    switch (choice) {
      case 1:
        print('========== Activity 1 ==========');

        String studentName = 'Juan Dela Cruz';
        int age = 20;
        double average = 91.75;
        bool isEnrolled = true;

        List<String> subjects = [
          'Mobile Application Development',
          'Statistics',
          'Intelligent Systems'
        ];

        print('Student Name : $studentName');
        print('Age          : $age');
        print('Average      : $average');
        print('Enrolled     : $isEnrolled');
        print('Subjects     : $subjects');
        break;

      case 2:
        print('========== Activity 2 ==========');

        int grade = 87;

        if (grade >= 90) {
          print('Grade: A');
        } else if (grade >= 80) {
          print('Grade: B');
        } else if (grade >= 70) {
          print('Grade: C');
        } else if (grade >= 60) {
          print('Grade: D');
        } else {
          print('Grade: F');
        }
        break;

      case 3:
        print('========== Activity 3 ==========');

        for (int i = 1; i <= 10; i++) {
          print('5 x $i = ${5 * i}');
        }
        break;

      case 4:
        print('========== Activity 4 ==========');

        double area = calculateArea(8, 5);
        print('Length : 8');
        print('Width  : 5');
        print('Area   : $area');
        break;

      case 5:
        print('========== Activity 5 ==========');

        Product product = Product('Laptop', 35000, 2);

        print('Product Name : ${product.name}');
        print('Price        : ${product.price}');
        print('Quantity     : ${product.quantity}');
        print('Total        : ${product.calculateTotal()}');
        break;

      case 6:
        print('========== Activity 6 ==========');

        Student student1 =
            Student('Jake', 21, email: 'jake@gmail.com');
        Student student2 = Student('Maria', 20);

        print('Student 1');
        student1.displayInfo();

        print('');

        print('Student 2');
        student2.displayInfo();
        break;

      case 0:
        print('Thank you! Program terminated.');
        break;

      default:
        print('Invalid choice. Please try again.');
    }

  } while (choice != 0);
}