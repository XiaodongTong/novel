

``` mermaid
graph TD
    subgraph 准备阶段
        A[Generate Outline<br/>生成大纲<br/>每批50章×6批] -->|BATCH_DONE| A
        A -->|COMPLETE<br/>300章完成| B[Review Outline<br/>审查大纲]
        B -->|CHANGES_MADE<br/>有修改| B
        B -->|APPROVED<br/>审查通过| C[Design Characters<br/>设计人物]
        B -->|FUNDAMENTAL_ISSUE<br/>根本性问题| A
    end

    subgraph 角色阶段
        C --> D[Review Characters<br/>审查角色]
        D -->|CHANGES_MADE<br/>有修改| D
        D -->|APPROVED<br/>审查通过| E[Simulate Plot<br/>推演剧情]
    end

    subgraph 推演阶段
        E --> F[Review Plot Simulation<br/>审查推演]
        F -->|CHANGES_MADE<br/>有修改| E
        F -->|FUNDAMENTAL_ISSUE<br/>角色与大纲矛盾| C
        F -->|APPROVED<br/>推演合理| G[Write Chapter<br/>写正文<br/>每次3章]
    end

    subgraph 写作循环
        G -->|BATCH_DONE<br/>写完3章| H[Review Chapter<br/>审查章节]
        G -->|WRITE_FAILED<br/>写作失败| G
        H -->|CHANGES_MADE<br/>有修改| H
        H -->|NEEDS_REWRITE<br/>需重写| G
        H -->|APPROVED_AND_CONTINUE<br/>通过，未满300章| G
        H -->|APPROVED_AND_COMPLETE<br/>通过，已满300章| I[Verify<br/>最终验证]
    end

    subgraph 收尾
        I -->|CHANGES_REQUESTED<br/>有问题| H
        I -->|INCOMPLETE<br/>章数/字数不足| G
        I -->|APPROVED<br/>全部通过| J((✅ 作品完成))
    end

    classDef stage fill:#1a1a2e,stroke:#e94560,stroke-width:2px,color:#eee
    classDef review fill:#16213e,stroke:#0f3460,stroke-width:2px,color:#eee
    classDef done fill:#0a3d0a,stroke:#4caf50,stroke-width:3px,color:#eee
    classDef loop fill:#3a0000,stroke:#ff6b6b,stroke-width:1px,color:#eee,stroke-dasharray:5 5

    class A,C,E,G stage
    class B,D,F,H,I review
    class J done
```