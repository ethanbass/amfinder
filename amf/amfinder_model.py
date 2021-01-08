# AMFinder - amfinder_model.py
#
# MIT License
# Copyright (c) 2021 Edouard Evangelisti, Carl Turner
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.



"""
ConvNet Builder.
Builds the convolutional neural networks used by AMFinder.

Constants
-----------
INPUT_SIZE - Size (in pixels) of input images.
COLONIZATION_NAME - Name of the root segmentation network.
MYC_STRUCTURES_NAME - Name of the AM fungal structure prediction network.

Functions
------------
convolutions - Builds convolution/maxpooling blocks.
fc_layers - Builds fully connected/dropout layers.
colonization - Builds a network for root segmentation.
myc_structures - Builds a network for AM fungal structure prediction.
load - main function, to be called from outside.
"""



import os
import keras

from keras.models import Model
from keras.layers import Input, Conv2D, MaxPooling2D, Flatten, Dense, Dropout
from keras.initializers import he_uniform

import amfinder_log as AmfLog
import amfinder_config as AmfConfig



INPUT_SIZE = 126
COLONIZATION_NAME = 'col'
MYC_STRUCTURES_NAME = 'myc'


def convolutions():
    """
    Builds convolution/maxpooling blocks.
    """

    kc = 32
    input_layer = Input(shape=(INPUT_SIZE, INPUT_SIZE, 3))

    # Convolution block 1: 126x126 -> 120x120
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C11')(input_layer)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C12')(x)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C13')(x)

    x = MaxPooling2D(pool_size=2, name='M1')(x)

    kc *= 2

    # Convolution block 2: 60x60 -> 56x56
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C21')(x)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C22')(x)

    x = MaxPooling2D(pool_size=2, name='M2')(x)

    kc *= 2

    # Convolution block 3: 28x28 -> 24x24
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C31')(x)
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C32')(x)

    x = MaxPooling2D(pool_size=2, name='M3')(x)

    # Last convolution: 12x12 -> 10x10
    x = Conv2D(kc, kernel_size=3, kernel_initializer=he_uniform(),
               activation='relu', name='C4')(x)

    # Final size: 5x5
    x = MaxPooling2D(pool_size=2, name='M4')(x)
    flatten = Flatten(name='F')(x)

    return (input_layer, flatten)



def fc_layers(x, label, count=1, activation='sigmoid'):
    """
    Builds fully connected layers (with dropout).
    """

    x = Dense(64, kernel_initializer=he_uniform(), activation='relu',
              name = f'FC{label}1')(x)
    x = Dropout(0.3, name = f'D{label}1')(x)
    x = Dense(16, kernel_initializer=he_uniform(), activation='relu',
              name = f'FC{label}2')(x)
    x = Dropout(0.2, name = f'D{label}2')(x)
    output = Dense(count, activation=activation, name=label)(x)

    return output



def colonization():
    """
    Builds a single-label, multi-class classifier to discriminate
    colonized (Y) and non-colonized (N) roots, and background (X).
    """

    input_layer, flatten = convolutions()
    output_layer = fc_layers(flatten, 'RS', count=3, activation='softmax')

    model = Model(inputs=input_layer,
                  outputs=output_layer,
                  name=COLONIZATION_NAME)

    model.compile(loss='categorical_crossentropy',
                  optimizer='adam',
                  metrics=['acc'])

    return model



def myc_structures():
    """
    Builds a multi-label, single-class classifier to identify
    arbuscules (A), vesicles (V), hyphopodia (H), and
    intraradical hyphae (IH).
    """

    input_layer, flatten = convolutions()
    output_layers = [fc_layers(flatten, x) for x in AmfConfig.get('header')]

    model = Model(inputs=input_layer,
                  outputs=output_layers,
                  name=MYC_STRUCTURES_NAME)

    model.compile(loss='binary_crossentropy',
                  optimizer='adam',
                  metrics=['acc'])

    return model



def load():
    """
    Loads a pre-trained network or initializes a new one.
    """

    path = AmfConfig.get('model')

    if path is not None and os.path.isfile(path):
    
        print(f'* Pre-trained network: {path}')
        model = keras.models.load_model(path)

        # Updates annotation level based on the structure of the
        # pre-trained model. The structure is determined by checking
        # the layer RS (Root Segmentation) and catching error, if any.
        try:

            model.get_layer('RS')
            AmfConfig.set('level', 1)
            print('* Classes: colonized (Myc+), '
                  'non-colonized (Myc-), background (X).')

        except ValueError:

            AmfConfig.set('level', 2)
            print('* Classes: arbuscule (A), vesicle (V), '
                  'hyphopodium (H), intraradical hypha (I).')

        return model

    else:

        if AmfConfig.get('run_mode') == 'train':

            print('* Initializes a new network.')

            if AmfConfig.get('level') == 1:

                return colonization()

            else:

                return myc_structures()
        
        else: # missing pre-trained model
        
            AmfLog.error('A pre-trained model is required in prediction mode',
                         exit_code=AmfLog.ERR_NO_PRETRAINED_MODEL)