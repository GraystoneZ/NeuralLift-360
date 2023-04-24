#!bin/bash

# !!!!!! IMPORTANT !!!!!!
# DIRNAME is also used as placeholder token, so make sure not to set it as simple english noun.
# For example, set if like "~~~_1".
GPU_ID=$1
DIRNAME=$2
INITIALIZER_TOKEN=$3
CENTER=$4   # "yes" for images smaller than 512x512, "no" for else.

mkdir -p preprocess/$DIRNAME
mkdir -p output/$DIRNAME
set -e
exec > >(tee "output/$DIRNAME/output.log") 2>&1

echo "GPU_ID=$1, DIRNAME=$2, INITIALIZER_TOKEN=$3, CENTER=$4"

START=`date +%s`

INPUT_FILES=("./input/$DIRNAME"/*)

if [ ${#INPUT_FILES[@]} -ne 1 ]; then
    echo "Error : There should be only one image file in input directory."
    exit
fi

INPUT_FILE=$(basename -- "${INPUT_FILES[0]}")
INPUT_NO_EXT=$(basename $INPUT_FILE ".png")

# Preprocess - mask
cp input/$DIRNAME/$INPUT_FILE preprocess/$DIRNAME/$INPUT_FILE
cd image-background-remove-tool
CUDA_VISIBLE_DEVICES=$GPU_ID python -m carvekit -i ../preprocess/$DIRNAME
cp fill_hole.py ../preprocess/$DIRNAME/fill_hole.py
cd ../preprocess/$DIRNAME
CUDA_VISIBLE_DEVICES=$GPU_ID python fill_hole.py
rm -f fill_hole.py
cd ../..

# Preprocess - depth
cd BoostingMonocularDepth
CUDA_VISIBLE_DEVICES=$GPU_ID python run.py --Final --data_dir ../input/$DIRNAME --output_dir  ../preprocess/$DIRNAME --depthNet 2
cd ..

if [ "$CENTER" == "yes" ]; then
    # Preprocess - center
    python center.py --prefix $INPUT_NO_EXT --path preprocess/$DIRNAME

    # Preprocess - text inversion
    MODEL_NAME="runwayml/stable-diffusion-v1-5"
    CUDA_VISIBLE_DEVICES=$GPU_ID accelerate launch text_inversion.py \
        --pretrained_model_name_or_path=$MODEL_NAME \
        --learnable_property="object" \
        --placeholder_token=$DIRNAME\
        --initializer_token=$INITIALIZER_TOKEN \
        --resolution=512 \
        --train_batch_size=1 \
        --gradient_accumulation_steps=4 \
        --max_train_steps=1000 \
        --learning_rate=5.0e-04 --scale_lr \
        --lr_scheduler="constant" \
        --lr_warmup_steps=0 \
        --output_dir="preprocess/$DIRNAME" \
        --im_path="preprocess/$DIRNAME/${INPUT_NO_EXT}_centered.png" \
        --mask_path="preprocess/$DIRNAME/${INPUT_NO_EXT}_centered_mask.png" \
        --checkpoints_total_limit 1
else
    # Preprocess - text inversion
    MODEL_NAME="runwayml/stable-diffusion-v1-5"
    CUDA_VISIBLE_DEVICES=$GPU_ID accelerate launch text_inversion.py \
        --pretrained_model_name_or_path=$MODEL_NAME \
        --learnable_property="object" \
        --placeholder_token=$DIRNAME\
        --initializer_token=$INITIALIZER_TOKEN \
        --resolution=512 \
        --train_batch_size=1 \
        --gradient_accumulation_steps=4 \
        --max_train_steps=1000 \
        --learning_rate=5.0e-04 --scale_lr \
        --lr_scheduler="constant" \
        --lr_warmup_steps=0 \
        --output_dir="preprocess/$DIRNAME" \
        --im_path="preprocess/$DIRNAME/${INPUT_NO_EXT}.png" \
        --mask_path="preprocess/$DIRNAME/${INPUT_NO_EXT}_mask.png" \
        --checkpoints_total_limit 1
fi

# Check preprocess time
MIDDLE=`date +%s`
PRETIME=$((MIDDLE - START))
PREHOURS=$((PRETIME / 3600))
PREMINUTES=$(( (PRETIME % 3600) / 60 ))
PRESECONDS=$(( (PRETIME % 3600) % 60 ))
echo "Runtime $PREHOURS:$PREMINUTES:$PRESECONDS (hh:mm:ss)"

# Train
CUDA_VISIBLE_DEVICES=$GPU_ID python main.py --config configs/$DIRNAME.yaml
    # --text "A high-resolution DSLR image of a $DIRNAME" \
    # --mask_path="preprocess/$DIRNAME/${INPUT_NO_EXT}_mask.png" \
    # --depth_path="preprocess/$DIRNAME/${INPUT_NO_EXT}.npy" \
    # --rgb_path="preprocess/$DIRNAME/${INPUT_NO_EXT}.png" \
    # --sd_name="preprocess/$DIRNAME"



END=`date +%s`
RUNTIME=$((END - START))
HOURS=$((RUNTIME / 3600))
MINUTES=$(( (RUNTIME % 3600) / 60 ))
SECONDS=$(( (RUNTIME % 3600) % 60 ))
echo "Runtime $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"