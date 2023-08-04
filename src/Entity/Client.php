<?php

namespace App\Entity;

use App\Interfaces\EntityInterface;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
#[ORM\Entity, ORM\HasLifecycleCallbacks]
class Client implements EntityInterface
{
    #[ORM\Id, ORM\Column, ORM\GeneratedValue]
    private int $id;

    #[ORM\Column(length: 36, unique: true)]
    private string $uuid;

    #[ORM\Column(unique: true, nullable: false)]
    private string $number;

    #[ORM\Column]
    private \DateTime $createdAt;

    #[ORM\Column(options: ['default' => false])]
    private bool $deleted = false;

    #[ORM\PrePersist]
    public function onPrePersist(): void
    {
        $this->createdAt = new \DateTime('NOW');
    }

    public function getId(): int
    {
        return $this->id;
    }

    public function setId(int $id): void
    {
        $this->id = $id;
    }

    public function getUuid(): string
    {
        return $this->uuid;
    }

    public function setUuid(string $uuid): void
    {
        $this->uuid = $uuid;
    }

    public function getNumber(): string
    {
        return $this->number;
    }

    public function setNumber(string $number): void
    {
        $this->number = $number;
    }

    public function getCreatedAt(): \DateTime
    {
        return $this->createdAt;
    }

    public function setCreatedAt(\DateTime $createdAt): self
    {
        $this->createdAt = $createdAt;

        return $this;
    }

    public function isDeleted(): bool
    {
        return $this->deleted;
    }

    public function setDeleted(bool $deleted): void
    {
        $this->deleted = $deleted;
    }
}