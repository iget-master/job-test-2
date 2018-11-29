<?php

namespace Tests\Integration;

use Tests\TestCase;
use App\User;
use App\Person;
use App\Http\Resources\User as UserResource;

class UserResourceTest extends TestCase
{
    /**
     * A basic test example.
     *
     * @return void
     */
    public function testItTransformsUserToArray()
    {
        $user = factory(User::class)->create();
        $user->touch();

        $response = UserResource::make($user)->toArray();

        $this->assertArraySubset([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'created_at' => $user->created_at->toIso8601String(),
            'updated_at' => $user->updated_at->toIso8601String(),
        ], $response);
    }
}
