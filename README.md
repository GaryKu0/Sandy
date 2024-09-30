
<h1 align="center">Sandy 🧽🌿</h1>

<img align="center" src="https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEjXemO3qq8pyUMQVplQ5myfaS8NoMJ-BJ6SMihxJMskLkMfTgxyuAqyLhmZEWuQhTCxN3pTLQ34U7RBuyPnDqQIpGP1JUbdsLs_7g9c3TVOkAr1vEXNPdBiTPbCjZ59aPlZrgB_8m8C1B5oDJrLq7XhbAt2Q2RKE14bxP74wlCTY3LgXHhFXA/s1400/sandy-cheeks-social.jpg"/>

![ios](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)
![swift](https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![html](https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white)


**Sandy** is your personal health assistant app inspired by SpongeBob's Sandy Cheeks. Just like Sandy keeps herself healthy and active underwater, our app helps you stay on top of your health goals through engaging tasks, real-time feedback, and intuitive interactions.

---

## 📋 Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [How to Add a New Task](#how-to-add-a-new-task)
- [How to Add a New Model](#how-to-add-a-new-model)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## ✨ Features

- **Real-Time Camera Integration**: Capture images and receive instant feedback on your health-related tasks.
- **Interactive Tasks**: Follow guided tasks with visual and auditory cues to ensure proper execution.
- **Countdown Timer**: Stay focused with built-in countdowns for each task.
- **Task Management**: Seamlessly switch between multiple health tasks.
- **Customizable Settings**: Adjust preferences to tailor the app to your personal needs.
- **Delightful UI**: Enjoy a user-friendly and visually appealing interface inspired by Sandy Cheeks.

---


## 🚀 Getting Started

Follow these instructions to set up **Sandy** on your local machine for development and testing purposes.

### 🛠 Prerequisites

- **Xcode 16.0** or later
- **iOS 18.0** or later

### 📦 Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/sandy.git
   cd sandy
   ```

2. **Open the Project in Xcode**

   ```bash
   open Sandy.xcodeproj
   ```

3. **Build and Run**

   - Select your desired simulator or connect your iOS device.
   - Press `Cmd + R` to build and run the app.

---

## 🎮 Usage

1. **Launch the App**

   Open **Sandy** on your iOS device.

2. **Navigate Through Tasks**

   - The home screen displays the current task with an accompanying icon.
   - Tap on a task to start it. A countdown timer will begin, guiding you through the activity.

3. **Monitor Progress**

   - During the countdown, follow the visual and auditory cues.
   - Upon completion, you'll receive a notification indicating task completion.

4. **Customize Settings**

   - Access the settings by tapping the gear icon in the top-right corner.
   - Add or remove models, adjust countdown durations, and toggle auto-processing features.

---

## ➕ How to Add a New Task

You can easily add new tasks to **Sandy** by modifying the `tasks` array in `ContentView.swift`.

### Steps:
1. Open `ContentView.swift`.
2. Locate the `@State private var tasks: [Task]` section.
3. Add a new `Task` object with your desired properties.

For example:

```swift
Task(
    name: "Jumping Jacks",
    expectedConditions: [2: "jumping", 4: "handsUp"],
    duration: 5,
    modelName: "jump-model",
    icon: "figure.walk",
    indexToLabelMap: [0: "standing", 1: "handsDown", 2: "jumping", 4: "handsUp"],
    multipliers: ["jumping": 1.2]
)
```

**Task parameters**:
- `name`: Name of the task.
- `expectedConditions`: Conditions for successful task completion.
- `duration`: Countdown duration in seconds.
- `modelName`: The custom model associated with this task.
- `icon`: A system icon representing the task.
- `indexToLabelMap`: Maps model output indices to readable labels.
- `multipliers`: Optional adjustments for model outputs.

---

## ➕ How to Add a New Model

You can add custom models to **Sandy** and load them dynamically.

### Steps:
1. **Host the Model**:
   - Ensure your TensorFlow model is accessible through a URL, or you can load it from IndexedDB after downloading it once.

2. **Register the Model in the HTML**:
   Open `index.html` and update the `modelNames` array under the `loadModels()` function.

   For example:
   ```javascript
   const modelNames = ['facing-model', 'jump-model']; // Add your new model here
   ```

3. **Add the Task in Swift**:
   After registering the model in the HTML, follow the steps in the **How to Add a New Task** section to associate the model with a task in `ContentView.swift`.

4. **Loading and Using the Model**:
   The app will try to load the model from IndexedDB or fetch it from the network. You can also preload models in IndexedDB for faster access.

   Ensure your model follows the required input/output format as expected by the app. 

---

## 🤝 Contributing

We welcome contributions from the community! To contribute to **Sandy**, please follow these steps:

1. **Fork the Repository**

2. **Create a Feature Branch**

   ```bash
   git checkout -b feature/YourFeatureName
   ```

3. **Commit Your Changes**

   ```bash
   git commit -m "Add your message here"
   ```

4. **Push to the Branch**

   ```bash
   git push origin feature/YourFeatureName
   ```

5. **Open a Pull Request**

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgements

- Inspired by **SpongeBob SquarePants'** Sandy Cheeks for her dedication to health and activity.
- Thanks to the open-source community for the tools and libraries that made this project possible.

---

> "Stay active and healthy just like Sandy Cheeks!" 🧽🌿
