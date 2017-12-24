using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Video;

public class GlitchController : MonoBehaviour
{
    public VideoClip clipReference;
    public Material glitchMaterial;

    public Renderer quadRenderer;

    public int playerCount = 4;
    public float timeOffsetBase = .25f;

    private VideoPlayer[] players;
    private RenderTexture[] textures;

    private bool firstFrame = true;

    public void Awake()
    {
        this.glitchMaterial = new Material(glitchMaterial);
        this.quadRenderer.sharedMaterial = glitchMaterial;

        this.players = new VideoPlayer[playerCount];
        this.textures = new RenderTexture[playerCount];

        for(int i = 0; i < playerCount; ++i)
        {
            this.textures[i] = new RenderTexture((int)clipReference.width, (int)clipReference.height, 0, RenderTextureFormat.ARGB32);
            this.textures[i].useMipMap = false;
            this.textures[i].wrapMode = TextureWrapMode.Clamp;
            this.textures[i].Create();

            glitchMaterial.SetTexture("_SourceTexture_" + i, this.textures[i]);

            this.players[i] = this.gameObject.AddComponent<VideoPlayer>();
            this.players[i].targetTexture = this.textures[i];
            this.players[i].playOnAwake = false;
            this.players[i].isLooping = true;
            this.players[i].audioOutputMode = VideoAudioOutputMode.None;
            this.players[i].clip = clipReference;
            this.players[i].Play();

            firstFrame = true;
        }
    }

    public void LateUpdate()
    {
        if (firstFrame)
        {
            for (int i = 0; i < playerCount; ++i)
                this.players[i].time = i * timeOffsetBase;

            firstFrame = false;
        }
    }

    private void OnApplicationFocus(bool focus)
    {
        if (focus)
        {
            for (int i = 0; i < playerCount; ++i)
            {
                if (!this.textures[i].IsCreated())
                    this.textures[i].Create();

                firstFrame = true;

                glitchMaterial.SetTexture("_SourceTexture_" + i, this.textures[i]);
            }
        }
    }
}