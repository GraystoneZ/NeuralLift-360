import yaml, json, types
import argparse

if __name__ == '__main__':
    
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', type=str, required=True, help='edited yaml config file')
    parser.add_argument('--text', type=str, required=True, help='text prompt')
    parser.add_argument('--mask_path', type=str, required=True, help='path to mask file')
    parser.add_argument('--depth_path', type=str, required=True, help='path to depth file')
    parser.add_argument('--rgb_path', type=str, required=True, help='path to rgb image file')
    parser.add_argument('--sd_name', type=str, required=True, help='directory of text inversion model')
    
    args = parser.parse_args()
    with open('configs/baseline.yaml', "r") as stream:
        try:
            opt = (yaml.safe_load(stream))
        except yaml.YAMLError as exc:
            print(exc)
    
    def load_object(dct):
        return types.SimpleNamespace(**dct)
    opt = json.loads(json.dumps(opt), object_hook=load_object)
    print(opt)

    opt.text = args.text
    opt.mask_path = args.mask_path
    opt.depth_path = args.depth_path
    opt.rgb_path = args.rgb_path
    opt.sd_name = args.sd_name

    with open(args.config, 'w') as f:
        yaml.safe_dump(opt, f)