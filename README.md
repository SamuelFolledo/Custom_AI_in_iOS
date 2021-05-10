# How to Create an Machine Learning Model from scratch and use it in an iOS app

This is a tutorial on how to create your own Machine Learning model from scratch and how to use it in your iOS app. 

## ML Model Type
This tutorial will be a YOLO (You Only Look Once) type of machine learning model as speed is a huge requirement for mobile devices. YOLO is one of the **single stage detectors** that runs the classifier once on the input image and do all of the work in a single pass.

## Tools and Tech Stacks
### Machine Learning Tools
- **[IBM Cloud Annotation](https://cloud.annotations.ai/)** - for labeling our dataset
- **Jupyter Notebook** - run our Python codes as well as creating, training, and saving our machine learning model
- **Libraries** - TuriCreate, Pandas

### iOS Development Tools
- **Xcode** - best IDE for iOS development
- **Libraries** - CoreML, UIKit

## Initial Setup for ML
**Note:** Only follow these instructions once. For updating or reopening, refer to the instructions under *How to Update Machine Learning Model*
1. With this repo downloaded, open Terminal and change directory to the project's directory
2. In Terminal, enter `$ cd ML`
3. If needed, install Python's [virtualenv](https://docs.python.org/3/tutorial/venv.html) to have an isolated Python environment.
    `$ pip install virtualenv`
    - *For a cheat sheet for virtualenv, click [here](https://zetcode.com/python/venv/)*
4. In Terminal, enter `$ python -m venv ML_Model_Env` to create a Python virtual environment on the ML_Model_Env
5. In Terminal, enter `$ cd ML_Model_Env` to go inside that directory
6. In Terminal, enter `$ source bin/activate` to activate Python environment. It should look like below
<img src="https://github.com/SamuelFolledo/Custom_AI_in_iOS/blob/master/static/images/python-env-activated.png?raw=true" width="400">

7. Install these libraries and its dependencies by running:
    - `(ML_Model_Env) ➜  ML_Model_Env $ pip install turicreate`
    - `(ML_Model_Env) ➜  ML_Model_Env $ pip install jupyter`
8. In Terminal, enter `(ML_Model_Env) ➜  ML_Model_Env $ jupyter notebook` to launch Jupyter Notebook in your browser and then open **Model Creator.ipnyb**
9. Once you are done, enter in Terminal `(ML_Model_Env) ➜  ML_Model_Env $ deactivate` to clean state and remove all installed packages

## How to Update Machine Learning Model
1. With this repo downloaded, open Terminal and change directory to the project's directory
2. In Terminal, enter `$ cd ML/ML_Model_Env` to go to ML_Model_Env directory
3. In Terminal, enter `$ source bin/activate` to activate Python environment. It should look like below
<img src="https://github.com/SamuelFolledo/Custom_AI_in_iOS/blob/master/static/images/python-env-activated.png?raw=true" width="400">

4. In Terminal, enter `(ML_Model_Env) ➜  ML_Model_Env $ jupyter notebook` to launch Jupyter Notebook in your browser and then open **Model Creator.ipnyb**


## For questions or opportunities, contact me at:
- [LinkedIn](https://linkedin.com/in/samuelfolledo)
- Email: samuelfolled@gmail.com
- [MakeSchool portfolio](https://www.makeschool.com/portfolio/samuelfolledo) - Expected gradutation date August 2021
