# R15 in-place run cycle

这是四相位跑步参考，不是固定模板。可按用户要求改变速度和动作性格，但必须保留每半周期的接触、落地压缩、后蹬/腾空和高收腿。首尾姿势完全一致；肘持续弯曲，肩与前腿反相，膝盖只用负 X 屈曲。

```json
{
  "version": 1,
  "label": "R15四相位原地奔跑",
  "durationSec": 0.67,
  "loop": true,
  "dipPeaks": [
    { "at": 0.16, "amount": 0.1, "width": 0.1 },
    { "at": 0.4, "amount": -0.12, "width": 0.09 },
    { "at": 0.66, "amount": 0.1, "width": 0.1 },
    { "at": 0.9, "amount": -0.12, "width": 0.09 }
  ],
  "keys": [
    { "t": 0, "pose": { "Hips": [0.08, -0.08, 0.02], "UpperTorsoJoint": [0.22, 0.22, -0.05], "Neck": [-0.04, -0.1, 0.03], "RightShoulder": [0.72, 0.2, 0.22], "RightElbow": [1.42, 0.05, -0.03], "LeftShoulder": [-0.92, -0.12, -0.28], "LeftElbow": [1.18, -0.05, 0.03], "RightHip": [-0.08, -0.04, 0.03], "RightKnee": [-0.55, 0.04, 0.02], "RightAnkle": [0.08, 0, -0.03], "LeftHip": [1.08, 0.04, -0.09], "LeftKnee": [-2.22, -0.04, -0.02], "LeftAnkle": [0.22, 0, 0.04] } },
    { "t": 0.125, "pose": { "Hips": [0.1, -0.04, 0.01], "UpperTorsoJoint": [0.24, 0.15, -0.03], "Neck": [-0.03, -0.07, 0.02], "RightShoulder": [0.48, 0.24, 0.25], "RightElbow": [1.6, 0.05, -0.04], "LeftShoulder": [-0.68, -0.16, -0.28], "LeftElbow": [1.28, -0.05, 0.03], "RightHip": [-0.32, -0.04, 0.02], "RightKnee": [-0.28, 0.03, 0.02], "RightAnkle": [0.42, 0, -0.03], "LeftHip": [1.12, 0.02, -0.08], "LeftKnee": [-0.95, -0.03, -0.02], "LeftAnkle": [-0.28, 0, 0.03] } },
    { "t": 0.25, "pose": { "Hips": [0.14, 0, 0], "UpperTorsoJoint": [0.26, 0.05, -0.01], "Neck": [-0.05, -0.02, 0.01], "RightShoulder": [0.05, 0.27, 0.22], "RightElbow": [1.74, 0.04, -0.04], "LeftShoulder": [-0.18, -0.24, -0.3], "LeftElbow": [1.48, -0.04, 0.04], "RightHip": [-0.22, -0.03, 0.01], "RightKnee": [-1.18, 0.02, 0.01], "RightAnkle": [0.48, 0, -0.02], "LeftHip": [0.72, 0.01, -0.06], "LeftKnee": [-0.88, -0.02, -0.01], "LeftAnkle": [-0.1, 0, 0.02] } },
    { "t": 0.375, "pose": { "Hips": [0.08, 0.06, -0.02], "UpperTorsoJoint": [0.22, -0.15, 0.03], "Neck": [-0.03, 0.07, -0.02], "RightShoulder": [-0.62, 0.12, 0.18], "RightElbow": [1.52, 0.04, -0.03], "LeftShoulder": [0.52, -0.32, -0.3], "LeftElbow": [1.68, -0.04, 0.04], "RightHip": [0.62, -0.02, 0.07], "RightKnee": [-2.05, 0.03, 0.02], "RightAnkle": [0.34, 0, -0.04], "LeftHip": [0.2, 0.03, -0.03], "LeftKnee": [-0.32, -0.03, -0.02], "LeftAnkle": [0.32, 0, 0.02] } },
    { "t": 0.5, "pose": { "Hips": [0.08, 0.08, -0.02], "UpperTorsoJoint": [0.22, -0.22, 0.05], "Neck": [-0.04, 0.1, -0.03], "RightShoulder": [-0.92, 0.12, 0.28], "RightElbow": [1.18, 0.05, -0.03], "LeftShoulder": [0.72, -0.2, -0.22], "LeftElbow": [1.42, -0.05, 0.03], "RightHip": [1.08, -0.04, 0.09], "RightKnee": [-2.22, 0.04, 0.02], "RightAnkle": [0.22, 0, -0.04], "LeftHip": [-0.08, 0.04, -0.03], "LeftKnee": [-0.55, -0.04, -0.02], "LeftAnkle": [0.08, 0, 0.03] } },
    { "t": 0.625, "pose": { "Hips": [0.1, 0.04, -0.01], "UpperTorsoJoint": [0.24, -0.15, 0.03], "Neck": [-0.03, 0.07, -0.02], "RightShoulder": [-0.68, 0.16, 0.28], "RightElbow": [1.28, 0.05, -0.03], "LeftShoulder": [0.48, -0.24, -0.25], "LeftElbow": [1.6, -0.05, 0.04], "RightHip": [1.12, -0.02, 0.08], "RightKnee": [-0.95, 0.03, 0.02], "RightAnkle": [-0.28, 0, -0.03], "LeftHip": [-0.32, 0.04, -0.02], "LeftKnee": [-0.28, -0.03, -0.02], "LeftAnkle": [0.42, 0, 0.03] } },
    { "t": 0.75, "pose": { "Hips": [0.14, 0, 0], "UpperTorsoJoint": [0.26, -0.05, 0.01], "Neck": [-0.05, 0.02, -0.01], "RightShoulder": [-0.18, 0.24, 0.3], "RightElbow": [1.48, 0.04, -0.04], "LeftShoulder": [0.05, -0.27, -0.22], "LeftElbow": [1.74, -0.04, 0.04], "RightHip": [0.72, -0.01, 0.06], "RightKnee": [-0.88, 0.02, 0.01], "RightAnkle": [-0.1, 0, -0.02], "LeftHip": [-0.22, 0.03, -0.01], "LeftKnee": [-1.18, -0.02, -0.01], "LeftAnkle": [0.48, 0, 0.02] } },
    { "t": 0.875, "pose": { "Hips": [0.08, -0.06, 0.02], "UpperTorsoJoint": [0.22, 0.15, -0.03], "Neck": [-0.03, -0.07, 0.02], "RightShoulder": [0.52, 0.32, 0.3], "RightElbow": [1.68, 0.04, -0.04], "LeftShoulder": [-0.62, -0.12, -0.18], "LeftElbow": [1.52, -0.04, 0.03], "RightHip": [0.2, -0.03, 0.03], "RightKnee": [-0.32, 0.03, 0.02], "RightAnkle": [0.32, 0, -0.02], "LeftHip": [0.62, 0.02, -0.07], "LeftKnee": [-2.05, -0.03, -0.02], "LeftAnkle": [0.34, 0, 0.04] } },
    { "t": 1, "pose": { "Hips": [0.08, -0.08, 0.02], "UpperTorsoJoint": [0.22, 0.22, -0.05], "Neck": [-0.04, -0.1, 0.03], "RightShoulder": [0.72, 0.2, 0.22], "RightElbow": [1.42, 0.05, -0.03], "LeftShoulder": [-0.92, -0.12, -0.28], "LeftElbow": [1.18, -0.05, 0.03], "RightHip": [-0.08, -0.04, 0.03], "RightKnee": [-0.55, 0.04, 0.02], "RightAnkle": [0.08, 0, -0.03], "LeftHip": [1.08, 0.04, -0.09], "LeftKnee": [-2.22, -0.04, -0.02], "LeftAnkle": [0.22, 0, 0.04] } }
  ]
}
```

Use this as a structural reference, not baked source data. Adapt the values to the user's requested speed and character of motion while preserving contact, landing compression, push-off/flight, high recovery, bent elbows, ankle articulation, and exact loop closure.

