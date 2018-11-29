<?php

namespace Tests\Integration;

use Tests\TestCase;
use App\User;
use App\Person;
use App\Http\Resources\Person as PersonResource;
use App\Http\Resources\User as UserResource;

class PersonResourceTest extends TestCase
{
    /**
     * A basic test example.
     *
     * @return void
     */
    public function testItTransformsPersonToArray()
    {
        $creator = factory(User::class)->create();
        $creator->touch();

        $person = factory(Person::class)->create([
            'type' => Person::TYPE_PERSON,
            'creator_id' => $creator->id,
        ]);

        $response = PersonResource::make($person)->toArray();

        $this->assertArraySubset([
            'id' => $person->id,
            'type' => $person->type,
            'name' => $person->name,
            'surname' => $person->surname,
            'gender' => $person->gender,
            'dob' => $person->dob->toIso8601String(),
            'bank_data' => $person->bank_data,
            'creator' => UserResource::make($creator)->toArray(),
            'created_at' => $creator->created_at->toIso8601String(),
            'updated_at' => $creator->updated_at->toIso8601String(),
        ], $response);
    }
}
